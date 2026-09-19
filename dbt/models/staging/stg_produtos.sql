with source as (

    select *
    from {{ source('raw_data', 'produtos') }}

),

renamed as (

    select
        cast(id_produto as int64) as id_produto,
        cast(sku as string) as sku,
        cast(nome as string) as nome,
        trim(cast(categoria as string)) as categoria,
        cast(preco_custo as numeric) as preco_custo

    from source

)

select *
from renamed