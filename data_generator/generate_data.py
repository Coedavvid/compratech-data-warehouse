import os
import random
from datetime import date, timedelta

import psycopg2
from faker import Faker


fake = Faker("pt_BR")

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "compratech",
    "user": "compratech",
    "password": os.environ["POSTGRES_PASSWORD"],
}


ESTADOS = [
    "SP", "RJ", "MG", "ES", "PR",
    "SC", "RS", "BA", "PE", "CE"
]

CATEGORIAS = [
    "Eletrônicos",
    "Informática",
    "Celulares",
    "Casa",
    "Esportes",
    "Moda"
]


def conectar_banco():
    return psycopg2.connect(**DB_CONFIG)


def gerar_clientes(cursor, quantidade=1000):
    print(f"Gerando {quantidade} clientes...")

    for _ in range(quantidade):
        cpf = fake.unique.numerify(text="###########")
        nome = fake.name()
        email = fake.unique.email()
        estado = random.choice(ESTADOS)

        data_cadastro = fake.date_between(
            start_date="-3y",
            end_date="today"
        )

        cursor.execute(
            """
            INSERT INTO clientes
                (cpf, nome, email, estado, data_cadastro)
            VALUES
                (%s, %s, %s, %s, %s)
            """,
            (
                cpf,
                nome,
                email,
                estado,
                data_cadastro
            )
        )


def gerar_produtos(cursor, quantidade=100):
    print(f"Gerando {quantidade} produtos...")

    for i in range(1, quantidade + 1):
        sku = f"SKU-{i:05d}"
        nome = fake.catch_phrase()
        categoria = random.choice(CATEGORIAS)

        preco_custo = round(
            random.uniform(20, 2000),
            2
        )

        cursor.execute(
            """
            INSERT INTO produtos
                (sku, nome, categoria, preco_custo)
            VALUES
                (%s, %s, %s, %s)
            """,
            (
                sku,
                nome,
                categoria,
                preco_custo
            )
        )


def gerar_vendas(cursor, quantidade=10000):
    print(f"Gerando {quantidade} vendas...")

    cursor.execute("SELECT id_cliente FROM clientes")
    clientes = [row[0] for row in cursor.fetchall()]

    cursor.execute("SELECT id_produto, preco_custo FROM produtos")
    produtos = cursor.fetchall()

    data_inicial = date.today() - timedelta(days=730)

    for i in range(quantidade):
        id_cliente = random.choice(clientes)

        id_produto, preco_custo = random.choice(produtos)

        data_venda = data_inicial + timedelta(
            days=random.randint(0, 730)
        )

        quantidade_produto = random.randint(1, 5)

        margem = random.uniform(1.2, 2.5)

        valor_unitario = round(
            float(preco_custo) * margem,
            2
        )

        valor_bruto = (
            quantidade_produto * valor_unitario
        )

        desconto = round(
            valor_bruto * random.uniform(0, 0.15),
            2
        )

        valor_total = round(
            valor_bruto - desconto,
            2
        )

        cursor.execute(
            """
            INSERT INTO vendas
                (
                    id_cliente,
                    id_produto,
                    data_venda,
                    quantidade,
                    valor_unitario,
                    valor_total,
                    valor_desconto
                )
            VALUES
                (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                id_cliente,
                id_produto,
                data_venda,
                quantidade_produto,
                valor_unitario,
                valor_total,
                desconto
            )
        )

        if (i + 1) % 1000 == 0:
            print(f"  {i + 1} vendas geradas...")


def main():
    print("Conectando ao PostgreSQL...")

    conexao = conectar_banco()
    cursor = conexao.cursor()

    try:
        gerar_clientes(cursor)
        gerar_produtos(cursor)
        gerar_vendas(cursor)

        conexao.commit()

        print()
        print("Dados gerados com sucesso!")
        print("1.000 clientes")
        print("100 produtos")
        print("10.000 vendas")

    except Exception as erro:
        conexao.rollback()
        print(f"Erro ao gerar dados: {erro}")
        raise

    finally:
        cursor.close()
        conexao.close()


if __name__ == "__main__":
    main()