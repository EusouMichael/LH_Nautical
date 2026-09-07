-- ============================================================
-- LH NAUTICAL - QUESTÃO 4
-- ANÁLISE DE CLIENTES
-- ============================================================
--
-- Objetivo:
-- Identificar os clientes de maior Ticket Médio,
-- considerando apenas clientes que compraram 13 ou mais
-- categorias distintas.
--
-- Em seguida, identificar a categoria que concentra
-- a maior quantidade de itens comprados por esse grupo.
--
-- ============================================================


-- ============================================================
-- PARTE 1 - MÉTRICAS DOS CLIENTES
-- ============================================================
--
-- Métricas:
--   Faturamento Total
--   Frequência
--   Ticket Médio
--   Diversidade de Categorias
--
-- ============================================================

WITH faturamento_frequencia AS (

    SELECT
        customer_id,

        SUM(total) AS faturamento_total,

        COUNT(DISTINCT id) AS frequencia

    FROM public.orders

    GROUP BY customer_id
),

diversidade AS (

    SELECT
        o.customer_id,

        COUNT(DISTINCT p.category_id)
            AS diversidade_categorias

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
    ff.customer_id,

    ff.faturamento_total,

    ff.frequencia,

    ROUND(
        ff.faturamento_total
        / NULLIF(ff.frequencia, 0),
        2
    ) AS ticket_medio,

    COALESCE(
        d.diversidade_categorias,
        0
    ) AS diversidade_categorias

FROM faturamento_frequencia ff

LEFT JOIN diversidade d
    ON d.customer_id = ff.customer_id

ORDER BY
    ticket_medio DESC,
    ff.customer_id;


-- ============================================================
-- PARTE 2 - TOP 10 CLIENTES
-- ============================================================
--
-- Critério:
--   Diversidade de categorias >= 13
--
-- Ranking:
--   Maior Ticket Médio
--
-- Desempate:
--   customer_id crescente
--
-- ============================================================

WITH faturamento_frequencia AS (

    SELECT
        customer_id,

        SUM(total) AS faturamento_total,

        COUNT(DISTINCT id) AS frequencia

    FROM public.orders

    GROUP BY customer_id
),

diversidade AS (

    SELECT
        o.customer_id,

        COUNT(DISTINCT p.category_id)
            AS diversidade_categorias

    FROM public.orders o

    JOIN public.order_items oi
        ON oi.order_id = o.id

    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id

    JOIN public.products p
        ON p.id = pv.product_id

    GROUP BY o.customer_id
),

clientes AS (

    SELECT
        ff.customer_id,

        ff.faturamento_total,

        ff.frequencia,

        ROUND(
            ff.faturamento_total
            / NULLIF(ff.frequencia, 0),
            2
        ) AS ticket_medio,

        COALESCE(
            d.diversidade_categorias,
            0
        ) AS diversidade_categorias

    FROM faturamento_frequencia ff

    LEFT JOIN diversidade d
        ON d.customer_id = ff.customer_id
)

SELECT
    customer_id,

    faturamento_total,

    frequencia,

    ticket_medio,

    diversidade_categorias

FROM clientes

WHERE diversidade_categorias >= 13

ORDER BY
    ticket_medio DESC,
    customer_id

LIMIT 10;


-- ============================================================
-- PARTE 3 - CATEGORIA MAIS COMPRADA PELO TOP 10
-- ============================================================
--
-- Métrica:
--   SUM(order_items.quantity)
--
-- Agrupamento:
--   Categoria do produto
--
-- ============================================================

WITH faturamento_frequencia AS (

    SELECT
        customer_id,

        SUM(total) AS faturamento_total,

        COUNT(DISTINCT id) AS frequencia

    FROM public.orders

    GROUP BY customer_id
),

diversidade AS (

    SELECT
        o.customer_id,

        COUNT(DISTINCT p.category_id)
            AS diversidade_categorias

    FROM public.orders o

    JOIN public.order_items oi
        ON oi.order_id = o.id

    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id

    JOIN public.products p
        ON p.id = pv.product_id

    GROUP BY o.customer_id
),

top_clientes AS (

    SELECT
        ff.customer_id

    FROM faturamento_frequencia ff

    JOIN diversidade d
        ON d.customer_id = ff.customer_id

    WHERE d.diversidade_categorias >= 13

    ORDER BY
        ff.faturamento_total
        / NULLIF(ff.frequencia, 0) DESC,

        ff.customer_id

    LIMIT 10
)

SELECT
    c.id AS category_id,

    c.name AS categoria,

    SUM(oi.quantity) AS quantidade_itens_comprados

FROM top_clientes tc

JOIN public.orders o
    ON o.customer_id = tc.customer_id

JOIN public.order_items oi
    ON oi.order_id = o.id

JOIN public.product_variants pv
    ON pv.id = oi.product_variant_id

JOIN public.products p
    ON p.id = pv.product_id

JOIN public.categories c
    ON c.id = p.category_id

GROUP BY
    c.id,
    c.name

ORDER BY
    quantidade_itens_comprados DESC,
    c.id;