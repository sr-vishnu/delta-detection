import duckdb
import os

def create_tables(db_path='storage/storage.db'):
    con = duckdb.connect(db_path)
    con.execute("INSTALL json; LOAD json;")
    

    schema = """
        ingestion_timestamp TIMESTAMP,
        batch_id STRING,
        batch_offset INTEGER,
        payload JSON
    """
    
    try:
        # recreate tables with the new schema
        con.execute(f"DROP TABLE IF EXISTS raw_profiles")
        con.execute(f"DROP TABLE IF EXISTS raw_memberships")
        
        con.execute(f"CREATE TABLE raw_profiles ({schema})")
        print("table 'raw_profiles' created.")
        
        con.execute(f"CREATE TABLE raw_memberships ({schema})")
        print("table 'raw_memberships' created.")
        
    except Exception as e:
        print(f"error occurred: {e}")
    finally:
        con.close()

if __name__ == "__main__":
    create_tables()
