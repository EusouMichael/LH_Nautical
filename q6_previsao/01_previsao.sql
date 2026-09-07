-- ============================================================
-- Q6 - PREVISÃO DE DEMANDA
-- Produtos analisados: 74 e 240
-- Método: média móvel recursiva de 3 meses
-- ============================================================

WITH vendas AS (
    SELECT
        DATE_TRUNC('month', o.placed_at)::date AS mes,
        SUM(oi.quantity) AS unidades_vendidas
    FROM public.orders o
    JOIN public.order_items oi
        ON oi.order_id = o.id
    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id
    WHERE pv.product_id IN (74, 240)
      AND o.placed_at < DATE '2026-01-01'
    GROUP BY DATE_TRUNC('month', o.placed_at)::date
),

-- Previsão de janeiro:
-- média dos três meses anteriores
previsao_jan AS (
    SELECT
        ROUND(AVG(unidades_vendidas)::numeric, 2) AS previsao
    FROM vendas
    WHERE mes BETWEEN DATE '2025-10-01' AND DATE '2025-12-01'
),

-- Previsão de fevereiro:
-- novembro + dezembro + previsão de janeiro
previsao_fev AS (
    SELECT
        ROUND(
            (
                v_nov.unidades_vendidas
                + v_dez.unidades_vendidas
                + p_jan.previsao
            ) / 3.0,
            2
        ) AS previsao
    FROM vendas v_nov
    JOIN vendas v_dez
        ON v_dez.mes = DATE '2025-12-01'
    CROSS JOIN previsao_jan p_jan
    WHERE v_nov.mes = DATE '2025-11-01'
),

-- Previsão de março:
-- dezembro + previsão de janeiro + previsão de fevereiro
previsao_mar AS (
    SELECT
        ROUND(
            (
                v_dez.unidades_vendidas
                + p_jan.previsao
                + p_fev.previsao
            ) / 3.0,
            2
        ) AS previsao
    FROM vendas v_dez
    CROSS JOIN previsao_jan p_jan
    CROSS JOIN previsao_fev p_fev
    WHERE v_dez.mes = DATE '2025-12-01'
)

SELECT
    DATE '2026-01-01' AS mes,
    previsao AS previsao_unidades
FROM previsao_jan

UNION ALL

SELECT
    DATE '2026-02-01',
    previsao
FROM previsao_fev

UNION ALL

SELECT
    DATE '2026-03-01',
    previsao
FROM previsao_mar

ORDER BY mes;