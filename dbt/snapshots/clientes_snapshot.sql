{% snapshot clientes_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='id_cliente',
        strategy='check',
        check_cols=['cpf', 'nome', 'email', 'estado', 'data_cadastro']
    )
}}

select
    id_cliente,
    cpf,
    nome,
    email,
    estado,
    data_cadastro

from {{ ref('stg_clientes') }}

{% endsnapshot %}
