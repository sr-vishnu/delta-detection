Algorithm: Process raw records into a historical entity table

1. Start a transaction
   - Treat the full processing run as one atomic operation.

2. Snapshot current state
   - Store all existing rows where `status = 'CURRENT'`.
   - This is used later to compare incoming records against the previous state.

3. Get the watermark
   - Find the latest processed `ingestion_timestamp`.
   - Only raw rows with `ingestion_timestamp` greater than this value are processed.

4. Reset previous delta flags
   - If new raw rows exist, set `delta = FALSE` for existing CURRENT rows.
   - Delta is rebuilt for the current processing run.

5. Find affected entities
   - Extract the configured entity identifiers from the new raw records.
   - Ignore rows where the required identifiers are null or empty.
   - For each entity, find the earliest incoming `ingestion_timestamp`.

6. Expire existing current rows
   - For entities present in the incoming records:
     - set existing CURRENT rows to `status = 'HISTORICAL'`
     - set `valid_to` to the entity’s earliest incoming `ingestion_timestamp`
     - set `delta = FALSE`

7. Read and structure new raw records
   - Read raw rows newer than the watermark.
   - Keep `ingestion_timestamp`, `batch_id`, `batch_offset`, `payload_hash`, and `metadata`.
   - Transform `payload` from JSON into the configured structured entity payload.

8. Order incoming versions
   - Partition rows by the configured entity identifiers.
   - Order by `ingestion_timestamp`, then `batch_offset`.
   - Calculate:
     - ascending row number
     - descending row number
     - previous `payload_hash`
     - next `ingestion_timestamp`

9. Assign status
   - Last row in each entity partition -> `CURRENT`
   - Earlier rows -> `HISTORICAL`

10. Assign action
    - For the first incoming row of an entity:
      - no matching previous CURRENT row -> `INSERT`
      - same `payload_hash` as previous CURRENT row -> `NOOP`
      - different `payload_hash` -> `UPDATE`
    - For later rows in the same entity partition:
      - same `payload_hash` as previous version -> `NOOP`
      - different `payload_hash` -> `UPDATE`

11. Build validity window
    - `valid_from` -> row `ingestion_timestamp`
    - `valid_to` -> next version’s `ingestion_timestamp`
    - For the final CURRENT row:
      - `valid_to` -> open-ended future timestamp

12. Rebuild delta
    - For each entity, check whether any `INSERT` or `UPDATE` happened in this run.
    - Only the final CURRENT row gets `delta = TRUE`.
    - This prevents a later `NOOP` from hiding an earlier real change.

13. Insert processed rows
    - Insert the calculated rows into the historical entity table.

14. Clean up temporary tables
    - Drop temporary state and watermark tables.

15. Commit transaction
    - Persist all changes together.