
import os
import sys
import json
import pandas as pd
from datetime import datetime
from src.modules.utils.validator import Validator
from src.modules.utils.executor import DuckDBSQLExecutor
from src.modules.contract.contract import CustomerProfile


# Add src to path to allow importing modules
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))



def _transform(payload_str):
    data = json.loads(payload_str)

    # top level cols to include as per output spec
    profile_keys = [
        "source_type",
        "source_id",
        "guest_type",
        "last_name",
        "first_name",
        "last_name_kana",
        "first_name_kana",
        "birthday",
        "emails",
        "phones",
        "addresses"
    ]

    # cols to include in the nested membership list
    membership_keys = [
        "program_id",
        "rank_name",
        "membership_id",
        "created_at"
    ]

    # only select the needed fields and construct a new object
    transformed = {
    **{k: data.get(k) for k in profile_keys},
    "memberships": [
        {k: m.get(k) for k in membership_keys}
        for m in data.get("memberships", [])
    ]
}
        
    return json.dumps(transformed, ensure_ascii=False)

def run_validation():
    # path constructions
    PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
    TRANSFORM_SQL_PATH = os.path.join(PROJECT_ROOT, 'src', 'sql', 'transforms', 'transformation.sql')
    OUTPUT_DIR = os.path.join(PROJECT_ROOT, 'src', 'output')

    TIMESTAMP = datetime.now().strftime("%Y%m%d%H%M%S")
    VERIFICATION_PATH = os.path.join(OUTPUT_DIR, f"verification-{TIMESTAMP}.jsonl")
    SYNC_PATH = os.path.join(OUTPUT_DIR, f"sync-{TIMESTAMP}.jsonl")
    
    # creaet dir if its not present
    os.makedirs(OUTPUT_DIR, exist_ok=True)


    try:
        df = DuckDBSQLExecutor.execute(TRANSFORM_SQL_PATH)
        _vdf = Validator.validate(df, CustomerProfile)
        
        # write the failed records to the verification file
        verification_df = _vdf[_vdf['valid'] == False].copy()
        verification_df['payload'] = verification_df['payload'].apply(json.loads)
        verification_df.to_json(VERIFICATION_PATH, orient='records', lines=True, force_ascii=False)

        # write the good ones to sync file
        sync_df = _vdf[_vdf["valid"] == True].copy()
        sync_df["payload"] = sync_df["payload"].apply(_transform).apply(json.loads)
        sync_df["payload"].to_json(
            SYNC_PATH,
            orient="records",
            lines=True,
            force_ascii=False
        )

    except Exception as e:
        print(f"an error occured: {e}")
        raise

if __name__ == "__main__":
    run_validation()
