with produtos as (

    select
        id_produto,
        sku,
        nome,
        categoria,
        preco_custo

    from {{ ref('stg_produtos') }}

),

dim_produto as (

    select
        farm_fingerprint(
            cast(id_produto as string)
        ) as id_produto_sk,

        id_produto,
        sku,
        nome,
        categoria,
        preco_custo

    from produtos

)

select *
from dim_produto