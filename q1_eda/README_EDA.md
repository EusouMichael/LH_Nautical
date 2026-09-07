# Q1 — EDA (Exploratory Data Analysis)

## Objetivo

Esta etapa corresponde à **Exploratory Data Analysis (EDA)** inicial do projeto LH Nautical.

O objetivo é realizar uma inspeção preliminar da tabela `orders` e do arquivo `orders.csv`, entendendo sua estrutura, dimensões, tipos de dados e algumas estatísticas básicas antes das análises posteriores.

---

## 1. Inspeção realizada

A análise inicial contempla:

- quantidade de linhas;
- quantidade de colunas;
- nomes das colunas;
- tipos de dados;
- primeiras linhas do conjunto de dados;
- menor e maior data de criação dos pedidos;
- menor valor de pedido;
- maior valor de pedido;
- valor médio dos pedidos.

---

## 2. Abordagem utilizada

A Q1 utiliza duas abordagens complementares:

### Python / Pandas

O arquivo `orders.csv` é carregado com Pandas para uma inspeção inicial do dataset.

São utilizados recursos como:

- `shape` para identificar dimensões;
- `columns` para listar as colunas;
- `dtypes` para verificar os tipos de dados;
- `head()` para visualizar os primeiros registros;
- funções de agregação como `min()`, `max()` e `mean()` para estatísticas básicas.

### PostgreSQL

A mesma estrutura é posteriormente analisada no banco PostgreSQL.

As consultas SQL permitem validar:

- quantidade de registros;
- quantidade de colunas;
- período dos pedidos;
- valores mínimo, máximo e médio da coluna `total`.

Para a quantidade de colunas, é utilizado o catálogo `information_schema.columns`.

---

## 3. Organização dos scripts

A pasta `q1_eda` contém os scripts utilizados durante a inspeção inicial.

### `01_inspecao_orders.py`

Realiza a inspeção estrutural do `orders.csv`, incluindo:

- dimensões;
- nomes das colunas;
- tipos de dados;
- primeiras linhas.

### `02_inspecao_orders.py`

Complementa a inspeção com as estatísticas solicitadas para a Q1:

- data mínima;
- data máxima;
- valor mínimo;
- valor máximo;
- valor médio.

### `q1_eda.sql`

Realiza as consultas equivalentes no PostgreSQL, permitindo validar a estrutura e as estatísticas diretamente sobre a tabela `orders`.

---

## 4. Relação entre Python e SQL

Python e PostgreSQL possuem papéis complementares nesta etapa.

| Aspecto | Python / Pandas | PostgreSQL |
|---|---|---|
| Dimensões | Sim | Sim |
| Colunas | Sim | Sim |
| Tipos de dados | Sim | — |
| Primeiros registros | Sim | — |
| Data mínima | Sim | Sim |
| Data máxima | Sim | Sim |
| Valor mínimo | Sim | Sim |
| Valor máximo | Sim | Sim |
| Valor médio | Sim | Sim |

A utilização das duas ferramentas permite realizar uma primeira exploração no arquivo bruto e, posteriormente, validar as informações dentro do banco de dados.

---

## 5. Observação técnica

Para análises temporais em Python, recomenda-se que a coluna `created_at` seja explicitamente convertida para o tipo datetime antes de operações sobre datas.

Exemplo:

```python
orders["created_at"] = pd.to_datetime(orders["created_at"])
```

Essa conversão é uma melhoria de robustez para a análise temporal e não altera o objetivo da EDA realizada.

---

## 6. Resultado da avaliação

A estrutura da Q1 foi considerada adequada para uma etapa inicial de EDA.

Os scripts apresentam uma sequência lógica:

**CSV → inspeção com Python → validação no PostgreSQL → base para as próximas análises.**

A Q1 não tem como objetivo realizar análises de negócio aprofundadas, mas sim estabelecer uma visão inicial da estrutura e das características básicas dos dados que serão utilizados nas etapas seguintes.

---

## Status

**Q1 — EDA: concluída e documentada.**
