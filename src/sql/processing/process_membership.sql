-- wrapping everything in a transaction because this process mutates the table
-- in multiple steps and i don't want to leave it in an inconsistent state
-- if something fails halfway through
BEGIN TRANSACTION;

-- taking a snapshot of the current state of the entities, this will be used later
CREATE TEMP TABLE current_state AS
SELECT *
FROM membership
WHERE status = 'CURRENT';

-- getting the current watermark so that we only process rows that arrived after it
-- this keeps the process idempotent without reprocessing rows that have already been handled
CREATE TEMP TABLE watermark_holder AS
SELECT
    COALESCE(
        MAX(ingestion_timestamp),
        '1900-01-01 00:00:00'::TIMESTAMP
    ) AS val
FROM membership;

-- delta is defined as the difference between successive batches
-- once a new batch arrives, the previous delta calculation no longer has meaning
-- so it's fine to invalidate the existing values and rebuild them later
UPDATE membership
SET delta = FALSE
WHERE status = 'CURRENT'
  AND EXISTS (
      SELECT 1
      FROM raw_membership
      WHERE ingestion_timestamp > (SELECT val FROM watermark_holder)
  );


-- we need the earliest ingestion time per entity because duplicates can exist
-- both within a batch and across multiple batches, more explanation below
WITH new_batch_first_times AS (
    SELECT
        (payload->>'$.source_type')::VARCHAR AS source_type,
        (payload->>'$.source_id')::VARCHAR AS source_id,
        (payload->>'$.program_id')::INTEGER AS program_id,
        (payload->>'$.membership_id')::VARCHAR AS membership_id,
        MIN(ingestion_timestamp) AS first_new_ingestion_time
    FROM raw_membership
    WHERE ingestion_timestamp > (SELECT val FROM watermark_holder)
      AND NULLIF(TRIM(payload->>'$.source_type'), '') IS NOT NULL
      AND NULLIF(TRIM(payload->>'$.source_id'), '') IS NOT NULL
      AND TRY_CAST(payload->>'$.program_id' AS INTEGER) IS NOT NULL
      AND NULLIF(TRIM(payload->>'$.membership_id'), '') IS NOT NULL
    GROUP BY 1, 2, 3, 4
)

-- if an entity appears in the incoming data, its existing CURRENT row
-- becomes HISTORICAL
UPDATE membership
SET
    status = 'HISTORICAL',
    valid_to = n.first_new_ingestion_time,
    delta = FALSE
FROM new_batch_first_times n
WHERE membership.membership.source_id = n.source_id
  AND membership.membership.source_type = n.source_type
  AND membership.status = 'CURRENT';

-- we fetch the raw data which is greater than the watermark from the raw table and expand the payload into indiviual cols
-- while preserving the structure of the payload
-- also excluding invalid rows which don't have the minimum required
-- entity identifiers populated
WITH new_raw_data AS (
    SELECT
        ingestion_timestamp,
        batch_id,
        batch_offset,
        payload_hash,
        metadata,
        payload->>'$.source_type' AS source_type,
        payload->>'$.source_id' AS source_id, 
json_transform(
    payload,
    '{
        "source_type": "VARCHAR",
        "source_id": "VARCHAR",
        "program_id": "INTEGER",
        "program_name": "VARCHAR",
        "membership_id": "VARCHAR",
        "rank_name": "VARCHAR",
        "created_at": "TIMESTAMP",
        "status": "VARCHAR"
    }'
) AS membership

    FROM raw_membership
    WHERE
        ingestion_timestamp > (SELECT val FROM watermark_holder)
        AND NULLIF(TRIM(payload->>'$.source_id'), '') IS NOT NULL
        AND NULLIF(TRIM(payload->>'$.source_type'), '') IS NOT NULL
),

-- the ingestion pipeline and the entity processing pipeline are intentionally
-- decoupled and can run independently of each other
-- this means the raw table may already contain multiple batches by the time
-- the processing pipeline runs, so duplicates can exist both within a batch
-- and across batches
-- because of that, we partition by the entity identifiers and order by
-- ingestion_timestamp and batch_offset
-- ingestion_timestamp orders batches, while batch_offset breaks ties
-- within the same batch
-- based on that ordering we calculate row numbers and lead/lag values
-- which are used by the next CTE
new_rows_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                membership.source_type,
                membership.source_id,
                membership.program_id,
                membership.membership_id
            ORDER BY ingestion_timestamp ASC, batch_offset ASC
        ) AS row_num_asc,

        ROW_NUMBER() OVER (
            PARTITION BY
                membership.source_type,
                membership.source_id,
                membership.program_id,
                membership.membership_id
            ORDER BY ingestion_timestamp DESC, batch_offset DESC
        ) AS row_num_desc,

        LAG(payload_hash) OVER (
            PARTITION BY
                membership.source_type,
                membership.source_id,
                membership.program_id,
                membership.membership_id
            ORDER BY ingestion_timestamp ASC, batch_offset ASC
        ) AS prev_payload_hash,

        LEAD(ingestion_timestamp) OVER (
            PARTITION BY
                membership.source_type,
                membership.source_id,
                membership.program_id,
                membership.membership_id
            ORDER BY ingestion_timestamp ASC, batch_offset ASC
        ) AS next_ingestion_time

    FROM new_raw_data
),
calculated_actions AS (
    SELECT
        n.*,

        -- since the rows are ordered by time, the last row in the partition
        -- represents the current state, everything else is historical
        CASE
            WHEN n.row_num_desc = 1 THEN 'CURRENT'
            ELSE 'HISTORICAL'
        END AS status,

        -- if a row is the first in its partition then if this particular entity
        -- was not present in the previous current state which we snapshotted before
        -- (current_state) then we know it is new and set its action to INSERT.
        -- otherwise it can either be UPDATE or NOOP depending on whether the
        -- payload has changed.
        --
        -- rows other than the first one cannot be INSERTs by definition,
        -- since there is already an earlier version in the partition.
        -- at that point the row can only be UPDATE or NOOP.
        CASE
            WHEN n.row_num_asc = 1 THEN
                CASE
                    WHEN e.membership.membership_id IS NULL THEN 'INSERT'
                    WHEN e.payload_hash = n.payload_hash THEN 'NOOP'
                    ELSE 'UPDATE'
                END
            ELSE
                CASE
                    WHEN n.payload_hash = n.prev_payload_hash THEN 'NOOP'
                    ELSE 'UPDATE'
                END
        END AS action,

        n.ingestion_timestamp AS valid_from,

        CASE
            WHEN n.row_num_desc = 1 THEN '9999-12-31 23:59:59'::TIMESTAMP
            ELSE n.next_ingestion_time
        END AS valid_to

    FROM new_rows_ranked n
    LEFT JOIN current_state e
        ON n.membership.source_type = e.membership.source_type
       AND n.membership.source_id = e.membership.source_id
       AND n.membership.program_id = e.membership.program_id
       AND n.membership.membership_id = e.membership.membership_id
),

-- rebuilding delta which we invalidated earlier
-- for a given entity, if at least one INSERT or UPDATE occurred in the batch,
-- the current row gets delta = TRUE
-- this avoids situations where a later NOOP masks an earlier change
-- for example:
-- [INSERT, UPDATE, UPDATE, NOOP]
-- if we only looked at the final row we would incorrectly conclude that
-- nothing changed, so we aggregate over the whole partition instead
delta_calc AS (
    SELECT
        *,
        BOOL_OR(action IN ('INSERT', 'UPDATE')) OVER (
            PARTITION BY
                membership.source_type,
                membership.source_id,
                membership.program_id,
                membership.membership_id
        ) AS has_change_in_batch
    FROM calculated_actions
)

INSERT INTO membership (
    ingestion_timestamp,
    batch_id,
    batch_offset,
    payload_hash,
    metadata,
    status,
    action,
    delta,
    valid_from,
    valid_to,
    source_type,

    source_id,
    program_id,
    membership_id,

    membership
)
SELECT
    ingestion_timestamp,
    batch_id,
    batch_offset,
    payload_hash,
    metadata,
    status,
    action,
    status = 'CURRENT' AND has_change_in_batch AS delta,
    valid_from,
    valid_to,

    membership.source_type,
    membership.source_id,
    membership.program_id,
    membership.membership_id,

    membership
FROM delta_calc;

DROP TABLE current_state;
DROP TABLE watermark_holder;

COMMIT;