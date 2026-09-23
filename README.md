# CompraTech Data Warehouse

Este projeto foi desenvolvido com o objetivo de colocar em prática conceitos que venho estudando na área de Dados, principalmente construção de Data Warehouse, modelagem dimensional, transformação e orquestração de dados.

Para isso, criei o cenário de uma empresa fictícia de e-commerce chamada **CompraTech**. A partir de dados de clientes, produtos e vendas armazenados em PostgreSQL, construí um fluxo para levar esses dados até o BigQuery, transformá-los com dbt e automatizar as etapas com Apache Airflow.

Durante o desenvolvimento, também trabalhei com conceitos como Star Schema, testes de qualidade de dados, Business Key, Surrogate Key e SCD Type 2.

## Arquitetura do Projeto

Para organizar o projeto, dividi o fluxo de dados em algumas etapas, desde a geração e armazenamento dos dados até a visualização final:

PostgreSQL → Python/Pandas → BigQuery (Raw) → dbt → BigQuery (Data Warehouse) → Looker Studio

O PostgreSQL representa o banco de origem da aplicação. A ingestão para o BigQuery é feita com Python e Pandas, enquanto o dbt é responsável pelas transformações e pela construção do modelo dimensional.

Depois de testar essas etapas separadamente, utilizei o Apache Airflow em Docker para automatizar a execução do pipeline.

## Tecnologias utilizadas

- **Python / Pandas:** geração dos dados fictícios e criação do processo de ingestão.
- **PostgreSQL:** banco de dados de origem, simulando o ambiente transacional.
- **Google BigQuery:** armazenamento dos dados brutos e das tabelas do Data Warehouse.
- **dbt Core:** transformação dos dados, criação do modelo dimensional e testes de qualidade.
- **Apache Airflow:** automação e orquestração das etapas do pipeline.
- **Docker / Docker Compose:** criação e execução do ambiente local do PostgreSQL e Airflow.
- **Looker Studio:** criação do dashboard para visualizar os resultados das vendas.
- **Git / GitHub:** versionamento e documentação do projeto.

## Dados

Para ter uma base de dados para trabalhar, gerei dados fictícios de clientes, produtos e vendas utilizando Python e a biblioteca Faker. Esses dados simulam as informações que poderiam vir do sistema transacional de um e-commerce.

A base utilizada no projeto contém:

- 1.000 clientes
- 100 produtos
- 10.000 vendas

Depois de gerar os dados, eles são armazenados no PostgreSQL, que funciona como banco de origem do projeto. Em seguida, criei um processo de ingestão em Python para extrair essas informações e carregá-las no dataset `raw_data` do BigQuery.
Mantive essa camada com os dados próximos ao formato original da fonte para depois realizar as transformações com dbt.

## Modelagem Dimensional

Para organizar os dados de forma mais adequada para análise, utilizei uma modelagem dimensional no formato Star Schema. Nesse modelo, as informações descritivas ficam nas dimensões, enquanto as vendas e suas métricas ficam concentradas na tabela fato.

### Dimensões

- `dim_cliente` — informações dos clientes
- `dim_produto` — informações dos produtos
- `dim_tempo` — calendário utilizado para análises temporais

### Tabela Fato

- `fact_vendas` — armazena as transações de vendas e métricas como quantidade, valor unitário, valor total e desconto

A tabela fato possui relacionamento com as dimensões de cliente, produto e tempo por meio de chaves substitutas (surrogate keys).

## Transformações com dbt

Depois que os dados chegam à camada `raw_data` no BigQuery, utilizo o dbt para realizar as transformações. Organizei os modelos em duas camadas principais: staging e marts.

Na camada de staging faço a preparação inicial dos dados vindos da fonte. Já na camada de marts ficam as dimensões, a tabela fato e os modelos que serão utilizados nas análises.

### Staging

- `stg_clientes`
- `stg_produtos`
- `stg_vendas`

### Marts

- `dim_cliente`
- `dim_produto`
- `dim_tempo`
- `fact_vendas`

Também foram criados modelos analíticos utilizados pelo dashboard:

- `receita_mensal`
- `top_5_produtos`

## Qualidade dos Dados

Além das transformações, utilizei os testes do dbt para verificar a qualidade dos dados e identificar possíveis problemas antes que eles chegassem às análises.

Foram utilizados testes como:

- `unique` – verifica se valores que deveriam ser únicos estão duplicados
- `not_null` – verifica a existência de valores nulos em campos obrigatórios
- `relationships` – verifica se os relacionamentos entre as tabelas estão consistentes
- `accepted_values` – verifica se determinados campos possuem apenas os valores esperados

Ao final, o projeto ficou com **28 testes executados com sucesso, sem warnings ou erros.**

## SCD Type 2

Um dos pontos que eu queria praticar neste projeto era como manter o histórico de alterações de uma dimensão. Para isso, implementei o conceito de Slowly Changing Dimension Type 2 (SCD Type 2) para os dados dos clientes.

A ideia é que, quando uma informação do cliente muda, o registro anterior não seja simplesmente sobrescrito. A versão antiga é mantida no histórico e uma nova versão passa a representar o estado atual do cliente.

Para controlar essas versões, utilizei os campos:

- `valid_from` – início da validade do registro
- `valid_to` – fim da validade do registro
- `is_current` – identifica qual versão é a atual

Inicialmente implementei esse processo utilizando dbt Snapshot no BigQuery. A primeira execução funcionou normalmente, mas ao tentar registrar uma alteração encontrei uma limitação do BigQuery Sandbox: a segunda execução precisava realizar operações DML, que não estavam disponíveis sem faturamento habilitado.

Como eu queria continuar o projeto sem gerar custos, reproduzi o comportamento do SCD Type 2 localmente no PostgreSQL. Para testar, alterei o estado de um cliente. A versão anterior do registro foi encerrada, preservando o histórico, e uma nova versão foi criada para representar o estado atual do cliente.

A demonstração utilizada para esse teste está em:

`scd2_demo/scd2_cliente.sql`

Com esse teste consegui validar na prática como o SCD Type 2 preserva o histórico de uma dimensão em vez de simplesmente sobrescrever os dados anteriores.

## Orquestração com Apache Airflow

Depois de validar a ingestão, as transformações e os testes separadamente, utilizei o Apache Airflow para juntar essas etapas em um único pipeline automatizado.

Criei a DAG `compratech_pipeline`, executada em ambiente Docker, com três tarefas principais:

1. Extrair os dados do PostgreSQL e carregá-los no BigQuery.
2. Executar o `dbt run` para atualizar os modelos do Data Warehouse.
3. Executar o `dbt test` para validar a qualidade dos dados após as transformações.

O fluxo ficou organizado da seguinte forma:

`PostgreSQL → BigQuery → dbt run → dbt test`

Dessa forma, em vez de executar cada etapa manualmente, consegui controlar a sequência e a execução do pipeline pelo Airflow. Ao final dos testes, a DAG foi executada de ponta a ponta com as três tarefas concluídas com sucesso.

## Dashboard no Looker Studio

Depois de preparar os dados no Data Warehouse, criei um dashboard no Looker Studio para visualizar alguns resultados das vendas.

Para facilitar essa etapa, criei com dbt dois modelos específicos para as visualizações:

- `receita_mensal` – reúne a receita das vendas por mês
- `top_5_produtos` – identifica os cinco produtos com maior quantidade vendida

Com esses dados, montei duas visualizações principais no dashboard:

- **Receita Total por Mês** – para acompanhar a evolução da receita ao longo do tempo
- **Top 5 Produtos mais Vendidos** - para visualizar quais produtos tiveram maior quantidade vendida 

O Looker Studio foi conectado diretamente às tabelas já transformadas no BigQuery, evitando utilizar os dados brutos da camada `raw_data` nas visualizações.

## Business Key e Surrogate Key

Durante a construção do modelo dimensional, trabalhei com a diferença entre Business Key e Surrogate Key.

A **Business Key** é uma chave que já existe no sistema de origem e possui significado dentro do negócio. No projeto, exemplos são o `id_cliente`, o `cpf` de um cliente e o `sku` de um produto.

Já a **Surrogate Key** é uma chave criada dentro do Data Warehouse para identificar os registros das dimensões sem depender diretamente das chaves do sistema de origem.

Essa separação se torna especialmente importante quando precisamos manter histórico. No SCD Type 2, por exemplo, um mesmo cliente pode continuar com a mesma Business Key, mas possuir diferentes Surrogate Keys para representar suas versões ao longo do tempo.

A tabela fato utiliza essas chaves para se relacionar com as dimensões, permitindo identificar corretamente qual registro da dimensão está associado a cada venda.

## Como executar o projeto

### Pré-requisitos

Para executar o projeto localmente é necessário ter instalado:

- Git
- Docker Desktop
- Docker Compose
- Python 3.12 ou superior
- Google Cloud CLI

### Configuração das variáveis de ambiente

Crie o arquivo `.env` a partir do exemplo disponível no projeto:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=compratech
POSTGRES_USER=compratech
POSTGRES_PASSWORD=sua_senha_aqui

GCP_PROJECT_ID=seu_project_id
BQ_DATASET_ID=raw_data
```
### Autenticação no Google Cloud

Para permitir que o pipeline acesse o BigQuery, utilizei Application Default Credentials (ADC) por meio do Google Cloud CLI.

Após fazer login no Google Cloud, a autenticação local pode ser configurada com:

```bash
gcloud auth application-default login
gcloud config set project SEU_PROJECT_ID
```

O arquivo `.env` contém configurações locais e credenciais e, por segurança, não é versionado no Git.

### Executando os serviços com Docker

Depois de configurar as variáveis de ambiente, os serviços do projeto podem ser iniciados com Docker Compose. Nesse ambiente, utilizei containers para executar o PostgreSQL e o Apache Airflow.

```bash
docker compose up -d
```

Para verificar se os containers estão em execução:

```bash
docker compose ps
```

A interface do Apache Airflow ficará disponível localmente na porta `8080`.
### Executando a ingestão de dados

A ingestão foi desenvolvida em Python para extrair os dados das tabelas do PostgreSQL e carregá-los na camada raw_data do BigQuery. O script utiliza Pandas durante o processo de extração e carregamento dos dados.

```bash
python data_generator/load_to_bigquery.py
```
### Executando as transformações com dbt

Depois que os dados estão disponíveis na camada raw_data, utilizo o dbt para executar as transformações e construir as tabelas do Data Warehouse. Os modelos incluem a camada de staging, as dimensões, a tabela fato e os modelos analíticos utilizados no dashboard.

```bash
cd dbt
dbt run --profiles-dir .
```

Após executar as transformações, utilizo os testes do dbt para validar a qualidade e a integridade dos dados antes de considerá-los prontos para análise.

```bash
dbt test --profiles-dir .
```

O pipeline também executa automaticamente essas etapas por meio da DAG `compratech_pipeline` no Apache Airflow.

## Estrutura do Projeto

```text
compratech-data-warehouse/
├── airflow/
│   ├── dags/
│   ├── plugins/
│   └── Dockerfile
├── data_generator/
│   ├── generate_data.py
│   └── load_to_bigquery.py
├── dbt/
│   ├── models/
│   └── snapshots/
├── docs/
│   └── images/
├── postgres/
├── scd2_demo/
│   └── scd2_cliente.sql
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

Cada diretório representa uma etapa da arquitetura, separando geração e ingestão de dados, transformação com dbt, orquestração com Airflow e demonstração do SCD Type 2.

## Evidências do Projeto

### Pipeline automatizado com Apache Airflow

Depois de validar cada etapa separadamente, utilizei o Apache Airflow para executar o pipeline de forma automatizada. A DAG compratech_pipeline controla a sequência entre a ingestão dos dados, as transformações com dbt e os testes de qualidade.

`PostgreSQL → BigQuery → dbt run → dbt test`

![Pipeline Apache Airflow](docs/images/airflow_pipeline.png)

### Transformações com dbt

Com os dados disponíveis no BigQuery, executei os modelos do dbt para transformar os dados brutos nas estruturas utilizadas pelo Data Warehouse. Nessa etapa são construídos os modelos de staging, as dimensões, a tabela fato e os modelos analíticos usados no dashboard.
Na execução final, os 9 modelos do projeto foram processados com sucesso:

![Execução dbt run](docs/images/dbt_run_success.png)

### Testes de qualidade com dbt

Depois das transformações, executei os testes do dbt para verificar se os dados estavam consistentes antes de utilizá-los nas análises. Foram validadas regras de unicidade, valores obrigatórios, relacionamentos entre as tabelas e valores esperados. Na execução final, os 28 testes passaram sem erros ou warnings.

![Execução dbt test](docs/images/dbt_test_success.png)

### Dashboard de Vendas

Para fechar o fluxo do projeto, conectei o Looker Studio aos dados já transformados no BigQuery e criei um dashboard para visualizar os resultados das vendas. Nele, acompanho a evolução da receita mensal e os cinco produtos com maior quantidade vendida.

![Dashboard de Vendas - CompraTech](docs/images/looker_dashboard.png) 