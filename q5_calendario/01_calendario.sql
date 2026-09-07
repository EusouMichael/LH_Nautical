-- ============================================================
-- LH NAUTICAL - QUESTÃO 5
-- DIMENSÃO DE CALENDÁRIO
-- ============================================================

-- Período baseado nas vendas físicas (POS)
-- A dimensão contempla todas as datas entre a menor
-- e a maior data de venda encontrada nos dados.

DROP VIEW IF EXISTS public.media_vendas_dia_semana;
DROP VIEW IF EXISTS public.vendas_diarias_pos;
DROP TABLE IF EXISTS public.dim_calendario;

CREATE TABLE public.dim_calendario AS

WITH periodo AS (

    SELECT
        MIN(placed_at::date) AS data_inicio,
        MAX(placed_at::date) AS data_fim

    FROM public.orders

    WHERE channel = 'pos'
),

calendario AS (

    SELECT
        generate_series(
            data_inicio,
            data_fim,
            INTERVAL '1 day'
        )::date AS data

    FROM periodo
)

SELECT
    data,

    EXTRACT(YEAR FROM data)::integer AS ano,

    EXTRACT(MONTH FROM data)::integer AS mes,

    EXTRACT(DAY FROM data)::integer AS dia,

    EXTRACT(ISODOW FROM data)::integer AS numero_dia_semana,

    CASE EXTRACT(ISODOW FROM data)::integer
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana

FROM calendario

ORDER BY data;

-- ============================================================
-- VENDAS DIÁRIAS - LOJAS FÍSICAS (POS)
-- ============================================================
--
-- Todos os dias da dimensão de calendário devem aparecer,
-- inclusive aqueles sem vendas.
--
-- Dias sem venda recebem valor = 0.
--
-- ============================================================

CREATE OR REPLACE VIEW public.vendas_diarias_pos AS

SELECT
    dc.data,
    dc.ano,
    dc.mes,
    dc.dia,
    dc.numero_dia_semana,
    dc.dia_semana,

    COALESCE(
        SUM(o.total),
        0
    ) AS vendas_diarias

FROM public.dim_calendario dc

LEFT JOIN public.orders o
    ON o.placed_at::date = dc.data
    AND o.channel = 'pos'

GROUP BY
    dc.data,
    dc.ano,
    dc.mes,
    dc.dia,
    dc.numero_dia_semana,
    dc.dia_semana

ORDER BY
    dc.data;

    -- ============================================================
-- MÉDIA DE VENDAS POR DIA DA SEMANA
-- ============================================================
--
-- A média considera TODOS os dias da dimensão calendário,
-- inclusive os dias sem venda, que possuem valor = 0.
--
-- ============================================================

CREATE OR REPLACE VIEW public.media_vendas_dia_semana AS

SELECT
    numero_dia_semana,
    dia_semana,

    COUNT(*) AS quantidade_dias,

    SUM(vendas_diarias) AS vendas_totais,

    ROUND(
        AVG(vendas_diarias),
        2
    ) AS media_vendas

FROM public.vendas_diarias_pos

GROUP BY
    numero_dia_semana,
    dia_semana

ORDER BY
    numero_dia_semana;