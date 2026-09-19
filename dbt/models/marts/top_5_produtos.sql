{{ config(materialized='table') }}

WITH produtos_agregados AS (
    SELECT
        p.id_produto,
        p.sku,
        p.nome AS produto,
        p.categoria,
        SUM(f.quantidade) AS quantidade_vendida,
        SUM(f.valor_total) AS receita_total
    FROM {{ ref('fact_vendas') }} AS f
    INNER JOIN {{ ref('dim_produto') }} AS p
        ON f.id_produto = p.id_produto_sk
    GROUP BY
        p.id_produto,
        p.sku,
        p.nome,
        p.categoria
),

produtos_ranqueados AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY quantidade_vendida DESC
        ) AS ranking
    FROM produtos_agregados
)

SELECT
    id_produto,
    sku,
    produto,
    categoria,
    quantidade_vendida,
    receita_total
FROM produtos_ranqueados
WHERE ranking <= 5