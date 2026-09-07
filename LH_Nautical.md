# LH Nautical — Projeto de Análise de Dados

**Desafio Lighthouse / Indicium AI**

## 1. Sobre o projeto

O desafio da LH Nautical começou com um conjunto de arquivos CSV e terminou em um dashboard no Power BI.

O trabalho foi dividido em sete partes:

1. EDA — análise exploratória da tabela `orders`
2. Schema — criação da estrutura no PostgreSQL
3. Carregamento — carga dos CSVs no banco
4. Análise de clientes
5. Dimensão de calendário
6. Previsão de demanda
7. Sistema de recomendação

A ideia foi seguir a sequência natural do trabalho: primeiro entender os dados, depois estruturar e carregar a base e, só então, partir para as análises.

O dashboard final reúne os principais resultados das etapas 4 a 7.

---

## 2. Objetivos

Os objetivos principais foram:

- verificar a qualidade inicial dos dados;
- montar a estrutura das tabelas no PostgreSQL;
- carregar os arquivos sem modificar os dados de origem;
- encontrar clientes com maior valor de compra;
- corrigir a análise por dia da semana com uma dimensão de calendário;
- testar um modelo simples de previsão de demanda;
- gerar uma recomendação de produto baseada em comportamento de compra;
- levar os resultados para o Power BI de forma que fossem fáceis de consultar.

---

## 3. Tecnologias utilizadas

| Tecnologia | Uso no projeto |
|---|---|
| PostgreSQL | Banco de dados e consultas SQL |
| SQL | EDA, clientes, calendário e consultas de apoio |
| Python 3 | Schema, carregamento, previsão e recomendação |
| Pandas | Tratamento e consolidação dos datasets usados nos modelos |
| NumPy | Cálculos numéricos da recomendação |
| Power BI | Dashboard e visualização |

---

## 4. Estrutura do projeto

```text
1-LH_NAUTICAL_CSV/
├── .vscode/
├── dashboard/
├── data/
│   └── raw/
├── docs/
├── q1_eda/
├── q2_schema/
├── q3_loading/
├── q4_clientes/
├── q5_calendario/
├── q6_previsao/
└── q7_recomendacao/
```

A pasta `data/raw` contém 24 arquivos CSV.


---

## 5. Banco de dados

O banco utilizado nas análises foi:

```text
Banco: lh_nautical
Schema: public
SGBD: PostgreSQL
```

Algumas contagens usadas como referência durante a validação:

| Tabela | Registros |
|---|---:|
| customers | 2.000 |
| products | 500 |
| product_variants | 1.009 |
| orders | 48.998 |
| order_items | 147.320 |
| payments | 53.546 |
| returns | 980 |
| employees | 15 |
| locations | 6 |
| suppliers | 25 |
| variant_attribute_values | 2.018 |

A auditoria realizada no banco também verificou as principais relações. Não foram encontrados pedidos sem cliente, IDs duplicados nas tabelas principais ou valores negativos nos campos monetários e de quantidade que foram checados.

---

# 6. Q1 — EDA

## Objetivo

Antes de usar a base para outras análises, foi feita uma leitura inicial da tabela `orders`.

A análise foi feita sem limpeza ou tratamento dos dados, conforme a regra da questão.

Foram verificados:

- quantidade de registros;
- menor e maior data;
- menor, maior e média de `total`;
- possíveis valores extremos;
- nulos e inconsistências.

### Resultado

```text
Registros: 48.998
Data inicial: 2020-01-01
Data final: 2026-12-31
Mínimo de total: R$ 32,62
Máximo de total: R$ 127.262,02
Média de total: R$ 28.704,99
```

A diferença entre a média e os valores mais altos da distribuição indica que existem pedidos de valor elevado que merecem atenção em uma análise mais aprofundada.

Na validação da tabela, `customer_id`, `created_at`, `subtotal`, `discount_amount` e `total` estavam preenchidos. Também não foram encontrados IDs duplicados em `orders` nem valores negativos em `total`.

### Conclusão da EDA

A tabela estava em condições de seguir para as próximas etapas. Isso não significa que toda e qualquer análise futura dispensaria validação adicional; a EDA serviu como uma primeira checagem da base.

---

# 7. Q2 — Schema PostgreSQL

## Objetivo

O objetivo dessa etapa foi transformar a estrutura dos CSVs em um `schema.sql` compatível com PostgreSQL.

O processo foi:

```text
CSV
 ↓
Inspeção das colunas
 ↓
Identificação dos tipos
 ↓
Regras de tipagem
 ↓
schema.sql
 ↓
Validação
```

Tipos principais utilizados:

```text
bool      → BOOLEAN
date      → DATE
timestamp → TIMESTAMP
int       → INTEGER
float     → NUMERIC
object    → TEXT
```

Para campos como CPF, CNPJ, telefone, SKU e outros identificadores, o tipo texto foi mantido quando necessário para não perder zeros à esquerda ou formatação original.

### Observação

A etapa de schema não teve como objetivo limpar os dados. Ela definiu a estrutura necessária para receber os arquivos no PostgreSQL.

---

# 8. Q3 — Carregamento dos CSVs

O carregamento foi implementado em Python 3 usando conexão com PostgreSQL.

O fluxo ficou:

```text
24 CSVs
  ↓
Conferência dos arquivos
  ↓
Conexão com PostgreSQL
  ↓
Verificação das tabelas
  ↓
Contagem no CSV x contagem no banco
  ↓
COPY
  ↓
COMMIT
```

Antes de carregar cada tabela, o script verifica se a tabela correspondente existe e compara a quantidade de registros.

A carga utiliza `COPY` para inserção em massa.

Também existe controle transacional:

```text
Sucesso → COMMIT
Erro    → ROLLBACK
```

A lógica foi feita para evitar uma nova carga quando a tabela já possuir a mesma quantidade de registros do CSV.

Durante a montagem da base houve dois pontos que exigiram atenção: um campo de telefone que não poderia ser tratado como inteiro e um problema de encoding em `variant_attribute_values`. Nesses casos, o schema/carga foi ajustado para preservar os valores originais, sem fazer uma limpeza dos arquivos.

---

# 9. Q4 — Análise de Clientes

## Objetivo

A questão buscava encontrar clientes de maior valor, considerando não apenas o faturamento, mas também frequência e diversidade de categorias.

As métricas usadas foram:

```text
Faturamento = SUM(orders.total)

Frequência = COUNT(DISTINCT orders.id)

Ticket Médio = Faturamento / Frequência

Diversidade = COUNT(DISTINCT products.category_id)
```

Para entrar no ranking, o cliente precisava ter comprado produtos de pelo menos **13 categorias diferentes**.

Depois do filtro, a ordenação foi:

```text
Ticket Médio DESC
customer_id ASC
```

e foram selecionados os 10 primeiros.

## Top 10

| Cliente | Faturamento | Frequência | Ticket Médio | Diversidade |
|---:|---:|---:|---:|---:|
| 1434 | R$ 1.333.282,13 | 36 | R$ 37.035,61 | 14 |
| 643 | R$ 1.320.268,68 | 36 | R$ 36.674,13 | 14 |
| 1563 | R$ 1.291.652,73 | 34 | R$ 37.989,79 | 13 |
| 740 | R$ 1.263.590,47 | 35 | R$ 36.102,58 | 14 |
| 633 | R$ 1.250.225,81 | 35 | R$ 35.720,74 | 14 |
| 177 | R$ 1.247.478,62 | 32 | R$ 38.983,71 | 14 |
| 877 | R$ 1.237.624,03 | 34 | R$ 36.400,71 | 14 |
| 1108 | R$ 1.228.274,20 | 39 | R$ 31.494,21 | 14 |
| 766 | R$ 1.205.948,00 | 42 | R$ 28.713,05 | 14 |
| 556 | R$ 1.199.307,24 | 39 | R$ 30.751,47 | 14 |

### Leitura do resultado

Os clientes do ranking combinam frequência relativamente alta, ticket médio alto e compra em várias categorias.

Isso é relevante para ações de retenção e cross-sell, principalmente porque o grupo já demonstra um comportamento de compra mais amplo.

---

# 10. Q5 — Dimensão de Calendário

## Problema

A análise inicial por dia da semana poderia ignorar os dias sem registro de venda.

Por exemplo, se uma determinada quarta-feira não tivesse nenhuma venda, essa data simplesmente não apareceria na tabela de vendas. Se a média fosse calculada diretamente sobre os registros existentes, o resultado ficaria baseado apenas nos dias em que houve venda.

## Solução

Foi criada uma dimensão de calendário com todas as datas do período analisado.

A tabela contém:

- data;
- ano;
- mês;
- dia;
- número do dia da semana;
- nome do dia da semana em português.

As vendas POS foram agregadas por dia e depois relacionadas ao calendário por `LEFT JOIN`.

Para os dias sem venda:

```sql
COALESCE(vendas_dia, 0)
```

Assim, um dia sem movimento entra na média como zero.

### Resultado

A média por dia da semana passa a considerar todos os dias do período, e não apenas os dias que possuem vendas registradas.

---

# 11. Q6 — Previsão de Demanda

## Objetivo

A questão pediu uma previsão mensal para o produto **Bússola de Bordo 702**, usando um baseline simples.

Durante a validação, o produto foi identificado pelos `product_id`:

```text
74
240
```

O treinamento considerou dados até:

```text
31/12/2025
```

O teste foi feito no primeiro trimestre de 2026.

## Método

Foi usada uma **média móvel recursiva de 3 meses**.

### Janeiro/2026

Meses usados:

```text
Out/2025 = 34
Nov/2025 = 60
Dez/2025 = 22
```

Cálculo:

```text
(34 + 60 + 22) / 3
= 38,67
```

### Fevereiro/2026

```text
(60 + 22 + 38,67) / 3
= 40,22
```

### Março/2026

```text
(22 + 38,67 + 40,22) / 3
= 33,63
```

## Previsão x realizado

| Mês | Previsão | Realizado | Erro absoluto |
|---|---:|---:|---:|
| Jan/2026 | 38,67 | 79 | 40,33 |
| Fev/2026 | 40,22 | 68 | 27,78 |
| Mar/2026 | 33,63 | 60 | 26,37 |

### MAE

```text
MAE = (40,33 + 27,78 + 26,37) / 3
MAE = 31,49 unidades
```

A soma das previsões para o trimestre foi:

```text
38,67 + 40,22 + 33,63 = 112,52 unidades
```

### Interpretação

As três previsões ficaram abaixo do realizado.

Para esse conjunto de dados, a média móvel funcionou como um baseline simples e fácil de explicar, mas o resultado mostra que ela não capturou toda a variação da demanda.

### Limitações

- usa uma janela curta de três meses;
- não modela tendência;
- não modela sazonalidade;
- não considera preço, promoção ou outras variáveis externas;
- é recursiva, portanto os erros podem afetar os meses seguintes;
- a avaliação foi feita somente sobre três meses.

Por isso, o resultado é mais adequado como ponto de partida do que como uma previsão definitiva de estoque.

---

# 12. Q7 — Sistema de Recomendação

## Objetivo

A questão pediu os produtos mais semelhantes ao **Motor de Popa 1949** com base no comportamento de compra dos clientes.

Produto de referência:

```text
product_id = 180
```

## Matriz Cliente x Produto

A matriz foi construída assim:

```text
Linhas  → customer_id
Colunas → product_id

1 → cliente comprou o produto
0 → cliente não comprou
```

A quantidade comprada não entra no cálculo.

Se o cliente comprou um produto várias vezes, continua sendo apenas:

```text
1
```

Essa escolha faz com que a comparação seja baseada na presença do produto no histórico do cliente.

## Similaridade

A comparação foi feita usando **Similaridde de Cosseno** entre os vetores de compra dos produtos.

O próprio Motor de Popa 1949 foi retirado do ranking.

## Resultado

| Ranking | Produto | Clientes em comum | Similaridade |
|---:|---|---:|---:|
| 1 | **Motor de Popa 5331** | 106 | **0,2566** |
| 2 | Cabo Náutico 2105 | 103 | 0,2562 |
| 3 | Vela Mestra 1913 | 100 | 0,2558 |
| 4 | Cabo Náutico 9048 | 99 | 0,2393 |
| 5 | GPS Plotter 6249 | 98 | 0,2377 |

O resultado mais alto foi:

> **Motor de Popa 5331 — similaridade 0,2566**

Esse ranking pode ser usado como base para uma vitrine de produtos relacionados ou para uma ação de cross-sell.

### Limitação

A recomendação depende do histórico disponível. Produtos novos ou com poucas compras tendem a ter pouca informação para uma comparação desse tipo.

Além disso, dois produtos podem ter compradores semelhantes sem que isso signifique, necessariamente, que sejam complementares.

---

# 13. Dashboard Power BI

O dashboard foi dividido em três páginas.

## Página 1 — Visão Geral

### KPIs

| Indicador | Resultado |
|---|---:|
| Faturamento | **R$ 1,41 Bi** |
| Pedidos | **48.998** |
| Clientes | **2.000** |
| Unidades Vendidas | **809.822** |
| Ticket Médio | **R$ 28.704,99** |

### Faturamento por canal

```text
E-commerce → R$ 987,21 Mi
POS        → R$ 419,27 Mi
```

### Faturamento anual

| Ano | Faturamento |
|---:|---:|
| 2020 | R$ 128,61 Mi |
| 2021 | R$ 144,82 Mi |
| 2022 | R$ 169,62 Mi |
| 2023 | R$ 193,95 Mi |
| 2024 | R$ 220,11 Mi |
| 2025 | R$ 255,67 Mi |
| 2026 | R$ 293,70 Mi |

Os valores anuais somam aproximadamente **R$ 1,40648 bilhão**, em linha com o faturamento total de **R$ 1.406.487.201,80**.

> **Observação:** os números de 2026 seguem o período existente no dataset do desafio, que vai até dezembro de 2026. Eles não representam necessariamente o acumulado do ano corrente em uma operação real.

---

## Página 2 — Clientes

### KPIs

```text
2.000 clientes
R$ 1,41 Bi faturamento
24,50 frequência média
R$ 28,69 mil ticket médio
13,87 categorias por cliente
```

A página mostra:

- Top 10 clientes por faturamento;
- tabela detalhada;
- diversidade de categorias x faturamento;
- frequência x faturamento.

Um dos pontos mais claros no gráfico é a relação positiva entre frequência e faturamento: os clientes que compram mais vezes tendem a acumular maior faturamento.

---

## Página 3 — Previsão e Recomendação

A terceira página reúne os dois modelos analíticos:

### Previsão

```text
Jan/2026 → 38,67
Fev/2026 → 40,22
Mar/2026 → 33,63
MAE      → 31,49
```

### Recomendação

O ranking mostra os cinco produtos mais semelhantes ao Motor de Popa 1949.

Destaque:

```text
Motor de Popa 5331
Cosine Similarity = 0,2566
```

---

# 14. Principais resultados

## Faturamento

O faturamento total foi de:

```text
R$ 1.406.487.201,80
```

com:

```text
48.998 pedidos
2.000 clientes
809.822 unidades vendidas
Ticket médio = R$ 28.704,99
```

O cálculo do ticket médio é consistente com:

```text
R$ 1.406.487.201,80 / 48.998
≈ R$ 28.704,99
```

## Canais

```text
E-commerce → R$ 987,21 Mi
POS        → R$ 419,27 Mi
```

O e-commerce é o maior canal em faturamento no período analisado.

## Clientes

O grupo de clientes com diversidade de pelo menos 13 categorias apresenta valores altos de ticket e frequência, o que o torna interessante para ações de relacionamento e cross-sell.

## Previsão

O baseline teve:

```text
MAE = 31,49 unidades
```

e subestimou as vendas nos três meses do teste.

## Recomendação

O produto mais próximo do Motor de Popa 1949 pelo comportamento dos compradores foi:

```text
Motor de Popa 5331
Similaridade = 0,2566
```

---

# 15. Recomendações de negócio

### Clientes

- acompanhar clientes com frequência e ticket elevados;
- criar ações específicas para clientes de alto valor;
- usar a diversidade de categorias como sinal para oportunidades de cross-sell.

### Produtos

- testar recomendações de produtos relacionados no e-commerce;
- avaliar ações de cross-sell para produtos com maior similaridade;
- acompanhar o desempenho das recomendações por conversão e ticket.

### Previsão

O próximo passo natural seria testar modelos que considerem um histórico maior e variáveis adicionais, como:

- tendência;
- sazonalidade;
- preço;
- promoção;
- calendário;
- outras variáveis externas disponíveis.

### Dashboard

Usar o Power BI como camada de consulta para as áreas de negócio, mantendo os indicadores principais e permitindo novas leituras sobre os dados sem refazer toda a análise.

---

# 16. Limitações

Alguns pontos devem ser considerados ao interpretar os resultados:

- a previsão é um baseline simples;
- a janela usada na previsão é curta;
- o período de teste possui somente três meses;
- a recomendação usa apenas presença/ausência de compra;
- Cosine Similarity não prova complementaridade entre produtos;
- o dashboard reflete as regras definidas no desafio.

---

# 17. Entregáveis

```text
LH_NAUTICAL/
├── dashboard/
│   └── LH_Nautical.pbix
├── data/
│   └── raw/
├── docs/
├── q1_eda/
├── q2_schema/
├── q3_loading/
├── q4_clientes/
├── q5_calendario/
├── q6_previsao/
└── q7_recomendacao/
```

Principais entregáveis:

- schema.sql
- scripts SQL das análises;
- scripts Python;
- Recomendacao.py;
- dashboard Power BI;
- este `README.md`.

---

# 18. Como reproduzir

## Pré-requisitos

- PostgreSQL
- Python 3
- Power BI Desktop

## Bibliotecas Python

As etapas que usam Python dependem das bibliotecas indicadas nos respectivos scripts. Para o conjunto principal:

```bash
pip install pandas numpy psycopg2
```

## Ordem de execução

```text
1. Criar o banco lh_nautical
2. Executar o schema.sql
3. Carregar os CSVs
4. Executar as consultas SQL
5. Executar os scripts Python das questões
6. Conferir os resultados
7. Abrir o dashboard no Power BI
```

---

# 19. Conclusão

O projeto passou por todas as etapas previstas no desafio, começando na inspeção dos dados e chegando à apresentação dos resultados no Power BI.

As análises mostraram:

- crescimento do faturamento ao longo do período;
- peso maior do e-commerce em relação ao POS;
- existência de um grupo de clientes com alta frequência, ticket e diversidade de compra;
- um baseline de previsão que subestimou a demanda no primeiro trimestre de 2026;
- produtos com comportamento de compra semelhante ao Motor de Popa 1949.

O resultado final é uma base organizada no PostgreSQL, um conjunto de análises em SQL/Python e um dashboard para consulta dos principais indicadores.

---

# 20. Status

| Etapa | Status |
|---|---|
| Q1 — EDA | ✅ Concluída |
| Q2 — Schema | ✅ Concluída |
| Q3 — Carregamento | ✅ Concluída |
| Q4 — Análise de Clientes | ✅ Concluída |
| Q5 — Dimensão de Calendário | ✅ Concluída |
| Q6 — Previsão de Demanda | ✅ Concluída |
| Q7 — Sistema de Recomendação | ✅ Concluída |
| Dashboard Power BI | ✅ Concluído |
| Documentação | ✅ Concluída |

---

## Autor

**Michael Ferreira dos Santos**

**Projeto:** LH Nautical — Lighthouse / Indicium AI  
**Área:** Data Analytics / Business Intelligence
