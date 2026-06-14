import os
import duckdb
import pandas as pd

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
# Going back 3 steps: utils -> modules -> src -> root
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(CURRENT_DIR)))
DB_PATH = os.path.join(PROJECT_ROOT, "storage", "storage.db")

class DuckDBSQLExecutor:
    @staticmethod
    def execute(sql_file_path):
        with open(sql_file_path, "r") as f:
            sql_query = f.read()

        con = duckdb.connect(DB_PATH)
        try:
            return con.execute(sql_query).df()
        finally:
            con.close()

    @staticmethod
    def ingest(df, table_name):
        con = duckdb.connect(DB_PATH)
        try:
            con.execute(f"INSERT INTO {table_name} SELECT * FROM df")
        finally:
            con.close()

