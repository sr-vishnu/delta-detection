CREATE OR REPLACE TABLE raw_membership (

    -- metadata created during ingestion, common for all entities.
    -- the etl_metadata field from the source file is extracted into metadata
    -- and excluded from hash generation because it has no business meaning.
    ingestion_timestamp TIMESTAMP,
    batch_id STRING,
    batch_offset INTEGER,
    payload_hash VARCHAR,
    metadata JSON,

    -- original source payload, stored as JSON before expansion into the entity table.
    payload JSON
);