```
├── docs -> contains all documentation
│   ├── ai-usage-advisory.md
│   ├── algo.load.md
│   ├── algo.processing.md
│   ├── algo.syncvalidation.md
│   ├── assumptions.md
│   ├── generality.md
│   ├── layout.md
│   └── nextsteps.md
├── operations -> this is the point of interaction with the whole project , this is where all orchestration happens
│   ├── destroy.sh -> destroys the whole database
│   ├── ingest.sh -> it creates the tables , ingests batches of data into the raw layer , then runs processing pipeline to populate the Entity layer
│   ├── prepare-sync.sh -> creates the sync ready jsonl file
│   └── reorder.sh -> this is to physically reorder the table to make it more performant
├── requirements.txt -> list of python dependencies used in this project
├── src
│   ├── data -> contains data used for testing
│   │   ├── customer_profile
│   │   │   ├── 20260101
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260102
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260103
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260104
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260105
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260106
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260107
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260108
│   │   │   │   └── batch.jsonl
│   │   │   ├── 20260109
│   │   │   │   └── batch.jsonl
│   │   │   └── 20260110
│   │   │       └── batch.jsonl
│   │   └── membership
│   │       ├── 20260101
│   │       │   └── batch.jsonl
│   │       ├── 20260102
│   │       │   └── batch.jsonl
│   │       ├── 20260103
│   │       │   └── batch.jsonl
│   │       ├── 20260104
│   │       │   └── batch.jsonl
│   │       ├── 20260105
│   │       │   └── batch.jsonl
│   │       ├── 20260106
│   │       │   └── batch.jsonl
│   │       ├── 20260107
│   │       │   └── batch.jsonl
│   │       ├── 20260108
│   │       │   └── batch.jsonl
│   │       ├── 20260109
│   │       │   └── batch.jsonl
│   │       └── 20260110
│   │           └── batch.jsonl
│   ├── modules
│   │   ├── contract
│   │   │   └── contract.py -> the contracts against which validation is performed
│   │   └── utils
│   │       ├── executor.py -> generic utility to run queries on DuckDB
│   │       └── validator.py -> generic utility to validate a Pydantic Model agains a payload col contained in a pandas dataframe
│   ├── output -> this is where o/p is writtern to
│   ├── scripts -> contains scripts which perform individual steps in our pipeline
│   │   ├── create.py
│   │   ├── load.py
│   │   ├── process.py
│   │   └── validate.py
│   └── sql
│       ├── ddl -> defines the shape of all tables involved
│       │   ├── entity
│       │   │   ├── customer_profile.sql
│       │   │   └── membership.sql
│       │   └── raw
│       │       ├── raw_customer_profile.sql
│       │       └── raw_membership.sql
│       ├── processing -> contains the core algorithm used to implement the SCD type2 like operation
│       │   ├── process_customer_profile.sql
│       │   └── process_membership.sql
│       └── transforms -> contains transformation queries to make the op structure as per the validation spec
│           └── transformation.sql
└── storage -> this is where duckdb stores everything
    └── storage.db
```