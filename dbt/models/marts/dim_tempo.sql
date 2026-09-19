with limites as (

    select
        min(data_venda) as data_inicial,
        max(data_venda) as data_final

    from {{ ref('stg_vendas') }}

),

calendario as (

    select
        data_completa

    from limites,
    unnest(
        generate_date_array(
            data_inicial,
            data_final,
            interval 1 day
        )
    ) as data_completa

),

dim_tempo as (

    select
        cast(format_date('%Y%m%d', data_completa) as int64) as id_data,
        data_completa,
        extract(year from data_completa) as ano,
        extract(month from data_completa) as mes,
        extract(day from data_completa) as dia,
        format_date('%A', data_completa) as dia_da_semana,

        false as eh_feriado

    from calendario

)

select *
from dim_tempo