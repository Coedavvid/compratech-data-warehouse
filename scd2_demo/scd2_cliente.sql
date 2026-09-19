-- ============================================================
-- CompraTech - Demonstração SCD Tipo 2
-- ============================================================
-- Esta implementação demonstra localmente o comportamento
-- histórico da dimensão cliente sem depender de DML no
-- BigQuery Sandbox.
-- ============================================================

DROP TABLE IF EXISTS dim_cliente_scd2_demo;

CREATE TABLE dim_cliente_scd2_demo (
    id_cliente_sk SERIAL PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    nome VARCHAR(150) NOT NULL,
    estado CHAR(2) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    is_current BOOLEAN NOT NULL
);

-- ------------------------------------------------------------
-- Versão histórica do cliente
-- Estado original: PE
-- ------------------------------------------------------------

INSERT INTO dim_cliente_scd2_demo (
    id_cliente,
    nome,
    estado,
    valid_from,
    valid_to,
    is_current
)
VALUES (
    1,
    'Vitor Montenegro',
    'PE',
    TIMESTAMP '2026-09-18 05:15:00',
    TIMESTAMP '2026-09-18 19:00:00',
    FALSE
);

-- ------------------------------------------------------------
-- Nova versão do cliente
-- Estado atual: SP
-- ------------------------------------------------------------

INSERT INTO dim_cliente_scd2_demo (
    id_cliente,
    nome,
    estado,
    valid_from,
    valid_to,
    is_current
)
SELECT
    id_cliente,
    nome,
    estado,
    TIMESTAMP '2026-09-18 19:00:00',
    NULL,
    TRUE
FROM clientes
WHERE id_cliente = 1;