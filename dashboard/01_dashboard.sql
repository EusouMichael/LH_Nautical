-- ============================================================
-- LH NAUTICAL - DASHBOARD
-- Camada analítica para Power BI
-- ============================================================


-- ============================================================
-- 1. KPIs GERAIS
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_kpis AS

SELECT
    ROUND(SUM(o.total), 2) AS faturamento_total,

    COUNT(*) AS total_pedidos,

    COUNT(DISTINCT o.customer_id) AS clientes_distintos,

    (
        SELECT SUM(oi.quantity)
        FROM public.order_items oi
    ) AS unidades_vendidas,

    ROUND(
        SUM(o.total) / NULLIF(COUNT(*), 0),
        2
    ) AS ticket_medio,

    MIN(o.placed_at) AS primeira_venda,

    MAX(o.placed_at) AS ultima_venda

FROM public.orders o;


-- ============================================================
-- 2. VALIDAÇÃO DA VIEW
-- ============================================================

SELECT *
FROM public.dashboard_kpis;

-- ============================================================
-- 3. DESEMPENHO POR CANAL
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_canais AS

SELECT
    o.channel AS canal,

    COUNT(*) AS pedidos,

    ROUND(
        SUM(o.total),
        2
    ) AS faturamento,

    ROUND(
        SUM(o.total) / NULLIF(COUNT(*), 0),
        2
    ) AS ticket_medio

FROM public.orders o

GROUP BY o.channel

ORDER BY faturamento DESC;


-- ============================================================
-- 4. VALIDAÇÃO DA VIEW
-- ============================================================

SELECT *
FROM public.dashboard_canais;

-- ============================================================
-- 5. EVOLUÇÃO MENSAL DE VENDAS
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_vendas_mensais AS

SELECT
    DATE_TRUNC('month', o.placed_at)::date AS mes,

    COUNT(*) AS pedidos,

    ROUND(
        SUM(o.total),
        2
    ) AS faturamento,

    ROUND(
        SUM(o.total) / NULLIF(COUNT(*), 0),
        2
    ) AS ticket_medio

FROM public.orders o

GROUP BY 1

ORDER BY 1;


-- ============================================================
-- 6. VALIDAÇÃO DA VIEW
-- ============================================================

SELECT
    COUNT(*) AS meses,
    MIN(mes) AS primeiro_mes,
    MAX(mes) AS ultimo_mes,
    SUM(pedidos) AS pedidos,
    ROUND(SUM(faturamento), 2) AS faturamento
FROM public.dashboard_vendas_mensais;

-- ============================================================
-- 7. ANÁLISE DE CLIENTES
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_clientes AS

WITH clientes_vendas AS (

    SELECT
        o.customer_id,

        ROUND(
            SUM(o.total),
            2
        ) AS faturamento_total,

        COUNT(*) AS frequencia,

        ROUND(
            SUM(o.total) / NULLIF(COUNT(*), 0),
            2
        ) AS ticket_medio

    FROM public.orders o

    GROUP BY o.customer_id
),

clientes_categorias AS (

    SELECT
        o.customer_id,

        COUNT(
            DISTINCT p.category_id
        ) AS diversidade_categorias

    FROM public.orders o

    JOIN public.order_items oi
        ON oi.order_id = o.id

    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id

    JOIN public.products p
        ON p.id = pv.product_id

    GROUP BY o.customer_id
)

SELECT
    cv.customer_id,
    cv.faturamento_total,
    cv.frequencia,
    cv.ticket_medio,
    COALESCE(
        cc.diversidade_categorias,
        0
    ) AS diversidade_categorias

FROM clientes_vendas cv

LEFT JOIN clientes_categorias cc
    ON cc.customer_id = cv.customer_id;


-- ============================================================
-- 8. VALIDAÇÃO DA VIEW
-- ============================================================

SELECT
    COUNT(*) AS clientes,

    ROUND(
        SUM(faturamento_total),
        2
    ) AS faturamento_total,

    SUM(frequencia) AS pedidos,

    ROUND(
        SUM(faturamento_total)
        / NULLIF(SUM(frequencia), 0),
        2
    ) AS ticket_medio

FROM public.dashboard_clientes;

-- ============================================================
-- 9. VENDAS POR DIA DA SEMANA - LOJAS FÍSICAS
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_vendas_semana AS

WITH calendario AS (

    SELECT
        dia::date AS data
    FROM generate_series(
        DATE '2020-01-01',
        DATE '2026-12-31',
        INTERVAL '1 day'
    ) AS dia
),

vendas_pos AS (

    SELECT
        o.placed_at::date AS data,
        SUM(o.total) AS vendas
    FROM public.orders o
    WHERE o.channel = 'pos'
    GROUP BY o.placed_at::date
)

SELECT
    EXTRACT(
        ISODOW FROM c.data
    )::integer AS numero_dia,

    CASE EXTRACT(ISODOW FROM c.data)::integer
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana,

    COUNT(*) AS quantidade_dias,

    ROUND(
        SUM(COALESCE(v.vendas, 0)),
        2
    ) AS vendas_totais,

    ROUND(
        AVG(COALESCE(v.vendas, 0)),
        2
    ) AS media_vendas_dia

FROM calendario c

LEFT JOIN vendas_pos v
    ON v.data = c.data

GROUP BY
    EXTRACT(ISODOW FROM c.data)::integer

ORDER BY numero_dia;


-- ============================================================
-- 10. VALIDAÇÃO DA VIEW
-- ============================================================

SELECT *
FROM public.dashboard_vendas_semana;

-- ============================================================
-- 11. PREVISÃO DE DEMANDA
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_previsao AS

WITH previsoes AS (

    SELECT *
    FROM (
        VALUES
            (DATE '2026-01-01', 38.67::numeric),
            (DATE '2026-02-01', 40.22::numeric),
            (DATE '2026-03-01', 33.63::numeric)
    ) AS v(mes, previsao_unidades)
),

realizados AS (

    SELECT
        DATE_TRUNC('month', o.placed_at)::date AS mes,
        SUM(oi.quantity)::numeric AS realizado_unidades

    FROM public.orders o

    JOIN public.order_items oi
        ON oi.order_id = o.id

    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id

    WHERE pv.product_id IN (74, 240)
      AND o.placed_at >= DATE '2026-01-01'
      AND o.placed_at < DATE '2026-04-01'

    GROUP BY 1
)

SELECT
    p.mes,

    p.previsao_unidades,

    r.realizado_unidades,

    ROUND(
        ABS(
            r.realizado_unidades
            - p.previsao_unidades
        ),
        2
    ) AS erro_absoluto

FROM previsoes p

LEFT JOIN realizados r
    ON r.mes = p.mes

ORDER BY p.mes;


-- ============================================================
-- 12. VALIDAÇÃO DA VIEW
-- ============================================================

SELECT *
FROM public.dashboard_previsao;

SELECT
    ROUND(
        AVG(erro_absoluto),
        2
    ) AS mae
FROM public.dashboard_previsao;

-- ============================================================
-- 13. RECOMENDAÇÃO DE PRODUTOS
-- Produto de referência: Motor de Popa 1949
-- product_id = 180
-- ============================================================

CREATE OR REPLACE VIEW public.dashboard_recomendacao AS

WITH compras AS (

    SELECT DISTINCT
        o.customer_id,
        pv.product_id
    FROM public.orders o

    JOIN public.order_items oi
        ON oi.order_id = o.id

    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id
),

clientes_por_produto AS (

    SELECT
        product_id,
        COUNT(*) AS total_clientes
    FROM compras
    GROUP BY product_id
),

clientes_motor AS (

    SELECT
        customer_id
    FROM compras
    WHERE product_id = 180
),

total_clientes_motor AS (

    SELECT
        COUNT(*) AS total_clientes
    FROM clientes_motor
),

intersecoes AS (

    SELECT
        c.product_id,
        COUNT(*) AS clientes_em_comum
    FROM compras c

    JOIN clientes_motor cm
        ON cm.customer_id = c.customer_id

    WHERE c.product_id <> 180

    GROUP BY c.product_id
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            (
                i.clientes_em_comum::numeric
                /
                SQRT(
                    tcm.total_clientes::numeric
                    * cpp.total_clientes
                )
            ) DESC,
            i.product_id
    ) AS ranking,

    i.product_id,

    p.name AS produto,

    i.clientes_em_comum,

    cpp.total_clientes AS clientes_produto,

    ROUND(
        i.clientes_em_comum::numeric
        /
        SQRT(
            tcm.total_clientes::numeric
            * cpp.total_clientes
        ),
        4
    ) AS cosine_similarity

FROM intersecoes i

JOIN clientes_por_produto cpp
    ON cpp.product_id = i.product_id

JOIN public.products p
    ON p.id = i.product_id

CROSS JOIN total_clientes_motor tcm

ORDER BY
    cosine_similarity DESC,
    i.product_id

LIMIT 5;


-- ============================================================
-- 14. VALIDAÇÃO DA RECOMENDAÇÃO
-- ============================================================

SELECT *
FROM public.dashboard_recomendacao;