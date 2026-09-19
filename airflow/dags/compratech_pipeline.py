from datetime import datetime

from airflow import DAG
from airflow.providers.standard.operators.bash import BashOperator


with DAG(
    dag_id="compratech_pipeline",
    description="Pipeline ETL/ELT CompraTech: PostgreSQL -> BigQuery -> dbt",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["compratech", "bigquery", "dbt"],
) as dag:

    extrair_postgres_bigquery = BashOperator(
        task_id="extrair_postgres_bigquery",
        bash_command="python /opt/airflow/data_generator/load_to_bigquery.py",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            "cd /opt/airflow/dbt && "
            "dbt run --profiles-dir ."
        ),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            "cd /opt/airflow/dbt && "
            "dbt test --profiles-dir ."
        ),
    )

    extrair_postgres_bigquery >> dbt_run >> dbt_test