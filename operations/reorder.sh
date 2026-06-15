#!/bin/bash

set -euo pipefail

TABLE_NAME="${1:?usage: ./reorder.sh <name>}"

python - "$0" "$TABLE_NAME" <<'PYTHON'
import re
import sys
import duckdb
from pathlib import Path

SCRIPT_PATH = Path(sys.argv[1]).resolve()
TABLE_NAME = sys.argv[2]


PROJECT_ROOT = SCRIPT_PATH.parents[1]
DB_PATH = PROJECT_ROOT / "storage" / "storage.db"

con = duckdb.connect(str(DB_PATH))

try:
    con.execute("BEGIN TRANSACTION")

    con.execute(f"""
        CREATE TABLE {TABLE_NAME}__reordered AS
        SELECT *
        FROM {TABLE_NAME}
        ORDER BY status
    """)

    con.execute(f"DROP TABLE {TABLE_NAME}")

    con.execute(
        f"""
        ALTER TABLE {TABLE_NAME}__reordered
        RENAME TO {TABLE_NAME}
        """
    )

    con.execute("COMMIT")

    print(f"reordered table '{TABLE_NAME}'")
    print(f"path: {DB_PATH}")

except Exception:
    con.execute("ROLLBACK")
    raise

finally:
    con.close()
PYTHON