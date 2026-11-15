from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id='ingestion_and_dbt_pipeline',
    schedule='@daily', 
    start_date=datetime(2023, 1, 1),
    catchup=False,
) as dag:

    # Task 1: Run the Python ingestion script
    ingest_task = BashOperator(
        task_id='run_ingestion',
        bash_command='python /opt/airflow/dags/ingestion.py',
    )

    # Task 2: Navigate to the dbt folder and run the models
    dbt_task = BashOperator(
        task_id='run_dbt',
        bash_command='cd /opt/airflow/data_pipeline_dbt && dbt run --profiles-dir .',
    )

    # Set the order of execution: Ingestion must succeed before dbt starts
    ingest_task >> dbt_task