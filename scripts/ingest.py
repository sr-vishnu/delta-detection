import duckdb
import click
import os

@click.command()
@click.argument('table', type=click.Choice(['profile', 'membership']))
@click.argument('date')
@click.option('--db-path', default='storage/storage.db')
def ingest(table, date, db_path):
    table_map = {'profile': 'raw_profiles', 'membership': 'raw_memberships'}
    target_table = table_map[table]
    file_path = os.path.join('data', table, date, 'batch.jsonl')
    
    con = duckdb.connect(db_path)
    try:
        query = f"""
            INSERT INTO {target_table}
            SELECT 
                now(),
                '{date}',
                row_number() OVER () - 1,
                to_json(r)
            FROM read_json_auto('{file_path}') as r
        """
        con.execute(query)
        print(f"ingsted {date} into {target_table}")
    except Exception as e:
        print(f"eror happend while ingesting: {e}")
        raise e
    finally:
        con.close()

if __name__ == "__main__":
    ingest()
