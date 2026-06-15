- The transformation logic is defined as an SQL query on top of the entity layer tables. The shape of the query result is designed to match the validation specification.

- Pydantic models are used to define row-level contracts, which are then used to validate each record.

- A `Validator` component is implemented that takes a Pandas DataFrame and a Pydantic Model as input. The DataFrame contains a single column, `payload`, which stores a JSON string conforming to the structure defined by the validation contract.

  The validator validates each payload against the Pydantic contract and produces two additional columns:

  - **valid** – Boolean indicating whether validation succeeded.
  - **details** – Contains validation details.

  If validation succeeds, `valid` is set to `TRUE` and `details` contains the string `"success"`. If validation fails, `valid` is set to `FALSE`, and `details` contains the error messages returned by Pydantic.

- Two types of output files are produced:

  1. **Sync-ready file** – Written in the form `sync-{YYYYMMDDHHMMSS}.jsonl`. This file contains only records where `valid = TRUE`. Before writing, a final transformation is applied to ensure that the output structure exactly matches the required output specification.

  2. **Verification file** – Written in the form `verification-{YYYYMMDDHHMMSS}.jsonl`. This file contains only records where `valid = FALSE`. Unlike the sync-ready file, records are written in the same structure in which they were validated, making it easier to understand why validation failed. In addition to the original payload, the file includes the `valid` and `details` columns, where `details` contains the validation errors returned by Pydantic.

- The generated output files are stored under `delta-detection/src/output`.