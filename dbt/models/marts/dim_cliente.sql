with clientes_historico as (

    select
        id_cliente,
        cpf,
        nome,
        email,
        estado,
        data_cadastro,
        dbt_valid_from,
        dbt_valid_to

    from {{ ref('clientes_snapshot') }}

),

dim_cliente as (

    select
        farm_fingerprint(
            concat(
                cast(id_cliente as string),
                '|',
                cast(dbt_valid_from as string)
            )
        ) as id_cliente_sk,

        id_cliente,
        cpf,
        nome,
        email,
        estado,
        data_cadastro,

        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,

        case
            when dbt_valid_to is null then true
            else false
        end as is_current

    from clientes_historico

)

select *
from dim_cliente