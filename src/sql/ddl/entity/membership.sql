CREATE OR REPLACE TABLE membership (

   -- cols needed for change tracking (common for all entities)
    ingestion_timestamp TIMESTAMP,
    batch_id STRING,
    batch_offset INTEGER,
    payload_hash VARCHAR,
    metadata JSON,
    status STRING,
    action STRING,
    delta BOOLEAN,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,

    -- entity specific keys which uniquely identify an entity (this varies per entity type)
    -- i kept a copy of them at the top level in case there are any performance penalties
    -- to keeping them only inside the structure below (need to do a bit more research
    -- on how duckdb treats nested columns)
    -- this duplicated copy will increase storage slightly, but for now that tradeoff
    -- seems acceptable
    source_type VARCHAR,
    source_id VARCHAR,
    program_id INTEGER,
    membership_id VARCHAR,

    -- the actual payload expanded into individual cols while still preserving its structure
    -- its possible that keeping things nested instead of flattening everything out
    -- might have some performance penalties (though definitely better than storing
    -- the whole thing as a json column)
    -- what i am optimizing for here is preserving the historical traceability of
    -- the entity without losing its original shape
    -- if this structure ever becomes a serious bottleneck we can always build
    -- specialized tables on top of it, but only after we've established that
    -- the performance is actually unbearable
    -- until then, lets just query this table directly and do any required
    -- transformations in the query itself
    membership STRUCT(
        source_type VARCHAR,
        source_id VARCHAR,
        program_id INTEGER,
        program_name VARCHAR,
        membership_id VARCHAR,
        rank_name VARCHAR,
        created_at TIMESTAMP,
        status VARCHAR
    )

);