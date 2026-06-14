import click
import os
import sys
from modules.utils.executor import DuckDBSQLExecutor

# Add src to path to allow importing modules
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


@click.command()
@click.argument('table_name', type=click.Choice(['customer_profile', 'membership']))
def process(table_name):
    # Calculate project root: two levels up from src/scripts/
    PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
    SQL_DIR = os.path.join(PROJECT_ROOT, 'src', 'sql', 'processing')
    SQL_PATH = os.path.join(SQL_DIR, f'process_{table_name}.sql')

    print(f"Processing table: {table_name}")
    try:
        DuckDBSQLExecutor.execute(SQL_PATH)
        print(f"Successfully processed {table_name}")
    except Exception as e:
        print(f"Error while processing {table_name}: {e}")
        raise

if __name__ == "__main__":
    process()