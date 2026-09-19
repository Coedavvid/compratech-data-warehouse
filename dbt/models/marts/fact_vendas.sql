with vendas as (

    select
        id_venda,
        id_cliente,
        id_produto,
        data_venda,
        quantidade,
        valor_unitario,
        valor_total,
        valor_desconto

    from {{ ref('stg_vendas') }}

),

clientes as (

    select
        id_cliente_sk,
        id_cliente,
        valid_from,
        valid_to,

        row_number() over (
            partition by id_cliente
            order by valid_from
        ) as versao_cliente

    from {{ ref('dim_cliente') }}

),

produtos as (

    select
        id_produto_sk,
        id_produto

    from {{ ref('dim_produto') }}

),

tempo as (

    select
        id_data,
        data_completa

    from {{ ref('dim_tempo') }}

),

fact_vendas as (

    select
        v.id_venda,

        c.id_cliente_sk as id_cliente,
        p.id_produto_sk as id_produto,
        t.id_data,

        v.quantidade,
        v.valor_unitario,
        v.valor_total,
        v.valor_desconto

    from vendas v

    inner join clientes c
        on v.id_cliente = c.id_cliente
        and (
            (
                c.versao_cliente = 1
                and cast(v.data_venda as timestamp) < c.valid_from
            )
            or
            (
                cast(v.data_venda as timestamp) >= c.valid_from
                and cast(v.data_venda as timestamp) < coalesce(
                    c.valid_to,
                    timestamp('9999-12-31')
                )
            )
        )

    inner join produtos p
        on v.id_produto = p.id_produto

    inner join tempo t
        on v.data_venda = t.data_completa

)

select *
from fact_vendas