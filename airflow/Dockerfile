FROM apache/airflow:3.1.0-python3.12

USER airflow

RUN pip install --no-cache-dir \
    dbt-bigquery==1.12.1 \
    google-cloud-bigquery \
    pandas \
    pyarrow \
    psycopg2-binary