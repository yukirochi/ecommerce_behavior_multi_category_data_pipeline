import duckdb


raw_file_path = '/opt/airflow/raw_files/test.csv'
db_uri = "postgresql://myuser:mypassword@my-postgres:5432/department_store"

con = duckdb.connect()
con.execute("INSTALL postgres;")
con.execute("LOAD postgres;")

con.execute(f"ATTACH '{db_uri}' AS my_postgres (TYPE postgres);")


con.execute("CREATE SCHEMA IF NOT EXISTS my_postgres.raw;")

con.execute(f"""
    DROP TABLE IF EXISTS my_postgres.raw.raw_data;
    
    CREATE TABLE my_postgres.raw.raw_data AS
    SELECT * FROM read_csv_auto('{raw_file_path}');
""")

print("Data ingested successfully!")