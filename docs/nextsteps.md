- The processing algorithm described in `algo.processing.md`, which is currently implemented under `delta-validation/sql/processing/*`, could be further generalized into a single `processing.sql.j2` template and reused across different entities. A `DBT macro` is a greate candidate for this.

  This is possible because the same set of system columns (`status`, `action`, `delta`, `valid_from`, and `valid_to`) is added to all entities, and the logic used to derive these columns is identical.

  The algorithm relies on a set of entity-specific identifiers to uniquely identify an instance of an entity. For example:

  - `customer_profile` uses `(source_id, source_type)`.
  - `membership` uses `(source_id, source_type, program_id, membership_id)`.

  Therefore, the algorithm could be generalized into a Jinja template that takes two inputs:

  - The entity name.
  - The list of identifier columns for that entity.
  - The structure of the entity.

  Everything else can be abstracted away within the template, allowing the same processing logic to be reused across multiple entities while minimizing code duplication.


- As discussed in previous sections, the `delta` flag only represents the difference between the current state of an entity table and the incoming batch being processed. As a consequence, when a new batch arrives, the delta corresponding to the previous batch is invalidated and is no longer available.

  One way to address this limitation would be to leverage a storage layer that supports time travel. With such a storage layer (could be iceberg), its possible to query previous snapshots of the entity tables and inspect how the `delta` values, as well as other aspects of the tables, looked at a particular point in time.

  This would allow historical deltas to be reconstructed without requiring additional logic or dedicated history tables.


- Although DuckDB does not support partitioning, we could still arrange the data so that related rows end up physically closer together. We could take advantage of this by periodically reordering the data to keep query performance reasonable.

  For this particular use case, ordering by the `status` column sounds reasonable, since it only has two possible values: `CURRENT` and `HISTORICAL`. This would cause rows with `status = CURRENT` to be grouped together, allowing DuckDB to leverage zone maps and skip row groups that contain only historical records, thereby avoiding unnecessary full table scans.

  A simple implementation of this idea can be found under `delta-detection/operations`.

- If we eventually reach a scale where DuckDB is no longer sufficient, then it is probably time to move to a storage layer that supports partitioning natively (like iceberg).

  In that case, we could take advantage of the characteristics of this specific problem and partition the data based on the `valid_to` column. Since current rows always have an open-ended `valid_to` value (effectively `9999-12-31`), all rows representing the current state would naturally end up in the same partition.

  Of course, this would result in many sparsely populated partitions for historical records. However, I do not think this is a major concern, since most queries are expected to be directed towards the current state of the entities. Querying the current state is essentially equivalent to:

  ```sql
  WHERE valid_to = '9999-12-31'
  ```

  which would allow the storage engine to perform partition pruning and only read the partition containing the current records, instead of scanning all historical data.

  In other words, we are exploiting the fact that current rows are heavily queried while historical rows are rarely touched.