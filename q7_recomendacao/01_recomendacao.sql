-- ============================================================
-- Q7 - SISTEMA DE RECOMENDAÇÃO
-- Produto de referência: Motor de Popa 1949 (product_id = 180)
-- ============================================================


-- 1. Base binária Cliente x Produto
-- Cada combinação representa apenas presença/ausência de compra.
-- A quantidade comprada é ignorada.

WITH compras AS (
    SELECT DISTINCT
        o.customer_id,
        p.id AS product_id
    FROM public.orders o
    JOIN public.order_items oi
        ON oi.order_id = o.id
    JOIN public.product_variants pv
        ON pv.id = oi.product_variant_id
    JOIN public.products p
        ON p.id = pv.product_id
),


-- 2. Quantidade de clientes que compraram cada produto

clientes_por_produto AS (
    SELECT
        product_id,
        COUNT(*) AS total_clientes
    FROM compras
    GROUP BY product_id
),


-- 3. Clientes que compraram o produto de referência

clientes_motor AS (
    SELECT
        customer_id
    FROM compras
    WHERE product_id = 180
),


-- 4. Quantidade de clientes que compraram o Motor de Popa 1949
--    Calculada dinamicamente, sem valor fixo.

total_clientes_motor AS (
    SELECT
        COUNT(*) AS total_clientes
    FROM clientes_motor
),


-- 5. Interseção entre os clientes do Motor de Popa 1949
--    e os clientes de cada outro produto.

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


-- 6. Ranking por Cosine Similarity

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            i.clientes_em_comum::numeric /
            SQRT(
                tcm.total_clientes::numeric
                * cpp.total_clientes
            ) DESC,
            i.product_id
    ) AS ranking,

    i.product_id,

    p.name AS produto,

    i.clientes_em_comum,

    cpp.total_clientes AS clientes_produto,

    ROUND(
        i.clientes_em_comum::numeric /
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