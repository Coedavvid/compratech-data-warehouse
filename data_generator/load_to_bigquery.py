import os

import psycopg2
import pandas as pd
from google.cloud import bigquery


PROJECT_ID = os.getenv("GCP_PROJECT_ID", "compratech-data-warehouse")
DATASET_ID = os.getenv("BQ_DATASET_ID", "raw_data")

POSTGRES_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "localhost"),
    "port": int(os.getenv("POSTGRES_PORT", "5432")),
    "database": os.getenv("POSTGRES_DB", "compratech"),
    "user": os.getenv("POSTGRES_USER", "compratech"),
    "password": os.environ["POSTGRES_PASSWORD"],
}


def conectar_postgres():
    return psycopg2.connect(**POSTGRES_CONFIG)


def extrair_tabela(conexao, tabela):
    print(f"Extraindo tabela {tabela}...")

    query = f"SELECT * FROM {tabela};"

    cursor = conexao.cursor()
    cursor.execute(query)

    dados = cursor.fetchall()
    colunas = [descricao[0] for descricao in cursor.description]

    cursor.close()

    dataframe = pd.DataFrame(dados, columns=colunas)

    print(f"{len(dataframe)} registros extraidos.")

    return dataframe


def carregar_bigquery(client, dataframe, tabela):
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{tabela}"

    print(f"Carregando {tabela} no BigQuery...")

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE"
    )

    job = client.load_table_from_dataframe(
        dataframe,
        table_id,
        job_config=job_config
    )

    job.result()

    tabela_bq = client.get_table(table_id)

    print(
        f"{tabela} carregada com sucesso: "
        f"{tabela_bq.num_rows} registros."
    )


def main():
    print("Iniciando pipeline PostgreSQL -> BigQuery")

    conexao = conectar_postgres()
    client = bigquery.Client(project=PROJECT_ID)

    tabelas = [
        "clientes",
        "produtos",
        "vendas"
    ]

    try:
        for tabela in tabelas:
            dataframe = extrair_tabela(conexao, tabela)
            carregar_bigquery(client, dataframe, tabela)

    finally:
        conexao.close()

    print("Pipeline finalizado com sucesso!")


if __name__ == "__main__":
    main()