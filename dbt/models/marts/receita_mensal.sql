{{ config(materialized='table') }}

SELECT
    t.ano,
    t.mes,
    DATE_TRUNC(t.data_completa, MONTH) AS mes_referencia,
    COUNT(DISTINCT f.id_venda) AS total_vendas,
    SUM(f.quantidade) AS total_itens_vendidos,
    SUM(f.valor_total) AS receita_total,
    SUM(f.valor_desconto) AS desconto_total
FROM {{ ref('fact_vendas') }} AS f
INNER JOIN {{ ref('dim_tempo') }} AS t
    ON f.id_data = t.id_data
GROUP BY
    t.ano,
    t.mes,
    mes_referencia
ORDER BY
    mes_referencia