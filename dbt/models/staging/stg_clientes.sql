with source as (

    select *
    from {{ source('raw_data', 'clientes') }}

),

renamed as (

    select
        cast(id_cliente as int64) as id_cliente,
        cast(cpf as string) as cpf,
        cast(nome as string) as nome,
        cast(email as string) as email,
        upper(trim(cast(estado as string))) as estado,
        cast(data_cadastro as date) as data_cadastro

    from source

)

select *
from renamed