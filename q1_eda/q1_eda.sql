-- Questão 1.1 - Análise Exploratória de Dados (EDA)

-- 1. Quantidade de linhas + estatísticas
SELECT
    COUNT(*) AS quantidade_linhas,
    MIN(created_at) AS data_minima,
    MAX(created_at) AS data_maxima,
    MIN(total) AS valor_minimo,
    MAX(total) AS valor_maximo,
    AVG(total) AS valor_medio
FROM orders;

-- 2. Quantidade de colunas
SELECT
    COUNT(*) AS quantidade_colunas
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'orders';