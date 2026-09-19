with source as (

    select *
    from {{ source('raw_data', 'vendas') }}

),

renamed as (

    select
        cast(id_venda as int64) as id_venda,
        cast(id_cliente as int64) as id_cliente,
        cast(id_produto as int64) as id_produto,
        cast(data_venda as date) as data_venda,
        cast(quantidade as int64) as quantidade,
        cast(valor_unitario as numeric) as valor_unitario,
        cast(valor_total as numeric) as valor_total,
        cast(valor_desconto as numeric) as valor_desconto

    from source

)

select *
from renamed