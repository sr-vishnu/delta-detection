Algorithm: Ingest JSONL batch into raw entity table

1. Accept ingestion inputs
   - Get the entity type from the CLI.
   - Get the batch date from the CLI.
   - Resolve the target raw table using the entity type.

2. Locate the source file
   - Build the file path using:
     - entity type
     - batch date
     - `batch.jsonl`

3. Read the JSONL file
   - Read each line as one JSON record.
   - Load all records into a dataframe.

4. Add ingestion metadata
   - Set one shared `ingestion_timestamp` for the whole batch.
   - Set `batch_id` from the batch date.
   - Set `batch_offset` from the row position inside the file.

5. Extract source metadata
   - Move `etl_metadata` into the raw table `metadata` column.
   - If `etl_metadata` is missing or invalid, use `{}`.
   - Exclude `etl_metadata` from the business payload.

6. Build payload
   - Exclude ingestion-generated columns and metadata columns.
   - Convert the remaining business fields into a sorted JSON string.
   - Store this as `payload`.

7. Generate payload hash
   - Run SHA-256 on the payload JSON string.
   - Store the result as `payload_hash`.
   - This hash is later used to detect payload equality.

8. Select raw table columns
   - Keep only:
     - `ingestion_timestamp`
     - `batch_id`
     - `batch_offset`
     - `payload_hash`
     - `metadata`
     - `payload`

9. Insert into DuckDB
   - Connect to the configured DuckDB database.
   - Insert the dataframe into the target raw table.

10. Close connection
   - Print ingestion result.
   - Close the DuckDB connection.