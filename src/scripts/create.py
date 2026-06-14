import os
import sys

# Add src to path to allow importing modules
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(SCRIPT_DIR, '..'))
from modules.utils.executor import DuckDBSQLExecutor

def create_tables():
    # Calculate project root: two levels up from src/scripts/
    PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
    DDL_ENTITY_DIR = os.path.join(PROJECT_ROOT, 'src', 'sql', 'ddl', 'entity')
    DDL_RAW_DIR = os.path.join(PROJECT_ROOT, 'src', 'sql', 'ddl', 'raw')

    # Explicitly define the 4 DDL files to execute
    DDL_FILES = [
        os.path.join(DDL_RAW_DIR, 'raw_customer_profile.sql'),
        os.path.join(DDL_RAW_DIR, 'raw_membership.sql'),
        os.path.join(DDL_ENTITY_DIR, 'customer_profile.sql'),
        os.path.join(DDL_ENTITY_DIR, 'membership.sql')
    ]

    for ddl_path in DDL_FILES:
        try:
            print(f"Executing DDL: {ddl_path}")
            DuckDBSQLExecutor.execute(ddl_path)
        except Exception as e:
            print(f"Error occurred while executing {ddl_path}: {e}")
            raise

if __name__ == "__main__":
    create_tables()
