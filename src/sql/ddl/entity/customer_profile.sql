CREATE OR REPLACE TABLE customer_profile (

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
    customer_profile STRUCT(
        source_type VARCHAR,
        source_id VARCHAR,
        guest_type VARCHAR,
        last_name VARCHAR,
        first_name VARCHAR,
        last_name_kana VARCHAR,
        first_name_kana VARCHAR,
        birthday DATE,
        emails STRUCT(
            is_primary BOOLEAN,
            email VARCHAR
        )[],
        phones STRUCT(
            is_primary BOOLEAN,
            category VARCHAR,
            phone_number VARCHAR,
            country_code VARCHAR
        )[],
        addresses STRUCT(
            is_primary BOOLEAN,
            postal_code VARCHAR,
            prefecture_or_state VARCHAR,
            city VARCHAR,
            street_address VARCHAR,
            building_name_and_number VARCHAR,
            full_address VARCHAR
        )[],
        tags VARCHAR[],
        created_at TIMESTAMP
    )

)