from pathlib import Path
import duckdb

current_dir = Path(__file__).parent
raw_file_path = current_dir / 'raw_files' / '2019-Oct.csv'

db_uri = "postgresql://myuser:mypassword@localhost:5433/department_store"

con = duckdb.connect()

con.execute("INSTALL postgres;")
con.execute("LOAD postgres;")

con.execute(f"ATTACH '{db_uri}' AS my_postgres (TYPE postgres);")

con.execute(f"""
            
        CREATE TABLE my_postgres.raw.raw_data AS
        SELECT * FROM read_csv_auto('{raw_file_path}')          


""")


