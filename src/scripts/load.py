import click
import os
import json
import pandas as pd
import hashlib
import sys
from datetime import datetime
from src.modules.utils.executor import DuckDBSQLExecutor

# Add src to path to allow importing modules
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


@click.command()
@click.argument('table', type=click.Choice(['raw_customer_profile', 'raw_membership']))
@click.argument('date')
def ingest(table, date):

    # a tiny utility func to create the payload , which is basically a json string
    def create_payload(row):
        return json.dumps(row[payload_cols].to_dict(), sort_keys=True)

    # Mapping raw table names to their data directory names
    table_to_dir = {
        'raw_customer_profile': 'customer_profile',
        'raw_membership': 'membership'
    }

    TARGET_TABLE = table
    SUB_DIR = table_to_dir[table]
    
    # Idempotence check at the ingestion layer.
    # If this batch already exists in the raw table,
    # skip ingestion to avoid loading the same batch more than once.
    check_query = f"SELECT 1 FROM {TARGET_TABLE} WHERE batch_id = '{date}' LIMIT 1"
    existing_batch = DuckDBSQLExecutor.execute(check_query)
    if not existing_batch.empty:
        print(f"batch already exist")
        return

    # Calculate project root: two levels up from src/scripts/
    PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
    FILE_PATH = os.path.join(PROJECT_ROOT, 'src', 'data', SUB_DIR, date, 'batch.jsonl')
    
    # read the content of the file into memory
    with open(FILE_PATH, 'r') as f:
        records = [json.loads(line) for line in f]
    
    df = pd.DataFrame(records)

    timestamp = datetime.now()
    df['ingestion_timestamp'] = timestamp
    df['batch_id'] = date
    df['batch_offset'] = df.index
    df['metadata'] = df['etl_metadata'].apply(lambda x: json.dumps(x) if isinstance(x, dict) else json.dumps({}))
  
    exclude_cols = {'ingestion_timestamp', 'batch_id', 'batch_offset', 'etl_metadata', 'metadata'}
    payload_cols = [c for c in df.columns if c not in exclude_cols and c != 'etl_metadata']
    
    df['payload'] = df.apply(create_payload, axis=1)
    df['payload_hash'] = df['payload'].apply(lambda x: hashlib.sha256(x.encode()).hexdigest())

    _df = df[[
        'ingestion_timestamp', 
        'batch_id', 
        'batch_offset', 
        'payload_hash', 
        'metadata',
        'payload'
    ]]

    # ingest into duckdb using the executor
    try:
        DuckDBSQLExecutor.ingest(_df, TARGET_TABLE)
        print(f"ingested {len(_df)} records for {date} into {TARGET_TABLE}")
    except Exception as e:
        print(f"error happened while ingesting: {e}")
        raise

if __name__ == "__main__":
    ingest()
