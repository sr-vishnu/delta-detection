- Although not explicitly mentioned in the requirements, I decided to split ingestion into two separate stages: **load** and **process**.

  The **load** stage is responsible for loading batches of data into the raw layer. Maintaining a raw layer is a common best practice, as it serves as an immutable append-only log that can be used to replay and reconstruct all downstream layers if needed. In this specific case, it is also useful for achieving idempotence, since the processing pipeline only needs to consider rows from the raw layer that have not been processed previously.

  Idempotence is enforced at the load stage by checking for the existence of the `batch_id` (date) in the target raw table before proceeding with ingestion. If the query `SELECT 1 FROM {TARGET_TABLE} WHERE batch_id = '{date}' LIMIT 1` returns any results, the script identifies that the batch has already been loaded and skips the ingestion process.

  During the load stage, several system columns are added, as they are required by subsequent steps:

  - **ingestion_timestamp** – Timestamp at which the batch was loaded. This value is the same for all records within a batch.
  - **batch_id** – Identifier of the batch being loaded.
  - **batch_offset** – Position of the record within the batch.
  - **payload_hash** – SHA-256 hash of the business payload, used during processing to determine whether two records are equivalent.
  - **metadata** – System-level information associated with the record. Since it has no business significance, it is excluded from hash generation.

  Similarly, the **process** stage enriches the final entity tables with several additional system columns used to track entity state and changes over time:

  - **status** – Indicates whether a row represents the current version of an entity (`CURRENT`) or a previous version (`HISTORICAL`).
  - **action** – Describes the type of change represented by the row. Newly observed entities are marked as `INSERT`, existing entities whose business payload has changed are marked as `UPDATE`, and records whose payload is identical to the previous version are marked as `NOOP`.
  - **delta** – Indicates whether a row belongs to the delta produced by the most recent processing run. Rows corresponding to `INSERT` and `UPDATE` actions are marked as `TRUE`. Before each processing run, previously calculated delta flags are invalidated, ensuring that the delta always represents the difference between the current state of the entity tables and the newly processed batch. Consequently, a row that was part of a previous delta may no longer be considered part of the current delta if no new changes affecting that entity are observed.
  - **valid_from** – Timestamp from which a particular version of the entity becomes valid. This corresponds to the `ingestion_timestamp` of the record.
  - **valid_to** – Timestamp at which a particular version ceases to be valid. This is derived from the `ingestion_timestamp` of the next chronological version of the same entity. For rows representing the current version, this value is `NULL`.

- It should also be noted that the load and process stages are intentionally decoupled. In principle, multiple batches may be loaded into the raw layer before the processing pipeline is executed. This is done to better reflect typical data engineering workflows.

  As implemented currently, the overall flow is:

  ```text
  load -> process -> transform -> validate -> write o/p
  ```

- I have also decided not to focus heavily on partitioning at this stage. This decision is based on two considerations.

  First, it is reasonable to assume that the data velocity for the `customer_profile` and `membership` entities is relatively low. Even with datasets in the millions of records, a reasonably sized machine should be able to handle them without introducing partitioning complexity.

  Second, the use of JSONL as both the input and output format suggests that the volume of data being written to the sync-ready files is not expected to be particularly large.

  For these reasons, I have chosen not to introduce partitioning at the moment. Potential partitioning strategies and related considerations have been included in the **Improvements** section.


- The sample output contains a `rank_id` field, but I was unable to find a corresponding `rank_id` attribute in the membership source data. The source does, however, contain a `rank_name`, which has been included in the output instead.

- The validation specification states that two users should not share the same email address, but it does not specify how such conflicts should be handled. Possible approaches could include removing all conflicting records, keeping only the first occurrence, keeping only the last occurrence, or invalidating the entire output. Since the expected behavior is not defined, I decided not to enforce this constraint.