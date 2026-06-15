## storage layers

### raw

stores data as it was received. This layer acts as an immutable append-only log and is primarily used for replayability and reconstruction of data. No schema is enforced at this stage.

### entity

contains the versioned history of entities, providing a clear trail of how an entity evolved over time. In this layer, the schema is expanded to reflect the actual structure of the entity.

## Overall flow

```text
load -> process -> transform -> validate -> write output
```


```text
                 Input JSONL files
                          |
                          v
                  +---------------+
                  |     load      |
                  +---------------+
                          |
                          v
        +--------------------------------------+
        |              raw layer               |
        |                                      |
        |  raw_customer_profile                |
        |  raw_membership                      |
        |                                      |
        |  immutable append-only log           |
        +--------------------------------------+
                          |
                          v
                  +---------------+
                  |    process    |
                  +---------------+
                          |
                          v
        +--------------------------------------+
        |             entity layer             |
        |                                      |
        |  customer_profile                    |
        |  membership                          |
        |                                      |
        |  versioned entity history            |
        +--------------------------------------+
                          |
                          v
                  +---------------+
                  |   transform   |
                  +---------------+
                          |
                          v
                  +---------------+
                  |    validate   |
                  +---------------+
                          |
                          v
                  +---------------+
                  | write output  |
                  +---------------+
                          |
                          v
              sync.jsonl + verification.jsonl
```

### load

loads data into the raw layer.

### process

builds and maintains the entity layer.

### transform

transforms the entity data into a form suitable for validation and output generation.

### validate

validates the transformed data against contracts expressed as Pydantic models.

### write output

writes the `sync.jsonl` and `verification.jsonl` files.

## Setup

```bash
git clone git@github.com:sr-vishnu/delta-detection.git
cd delta-detection
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Operations

The load and process steps are orchestrated by `operations/ingest.sh`:

```bash
./operations/ingest.sh
```

The transform, validate, and output generation steps are orchestrated by `operations/prepare-sync.sh`:

```bash
./operations/prepare-sync.sh
```

## maintenance

remove DuckDB storage:

```bash
./operations/destroy.sh
```

reorder a DuckDB table to improve query performance:

```bash
./operations/reorder.sh <table_name>
```