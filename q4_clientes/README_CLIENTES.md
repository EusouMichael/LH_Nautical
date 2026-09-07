# Q4 — Análise de Clientes

## 1. Objetivo

A Q4 tem como objetivo analisar o comportamento dos clientes a partir dos pedidos realizados, calculando métricas de valor, frequência e diversidade de categorias.

A análise é dividida em três partes:

1. métricas de todos os clientes;
2. identificação dos Top 10 clientes com pelo menos 13 categorias distintas;
3. identificação da categoria mais comprada pelo grupo Top 10.

---

## 2. Fluxo da Q4

```text
orders
   │
   ├───────────────► Faturamento total
   │
   ├───────────────► Frequência de pedidos
   │
   └── order_items
          │
          ▼
    product_variants
          │
          ▼
       products
          │
          ▼
      categories
          │
          ▼
Diversidade de categorias
          │
          ▼
Clientes com ≥ 13 categorias
          │
          ▼
Ranking por ticket médio
          │
          ▼
Top 10 clientes
          │
          ▼
Categorias compradas pelo Top 10
          │
          ▼
Categoria com maior quantidade de itens
```

---

## 3. Parte 1 — Métricas dos clientes

A primeira parte calcula, para cada cliente:

- faturamento total;
- frequência de pedidos;
- ticket médio;
- diversidade de categorias.

### 3.1 Faturamento total

O faturamento é calculado pela soma do valor total dos pedidos:

```sql
SUM(total)
```

A métrica representa o valor agregado dos pedidos associados ao cliente.

### 3.2 Frequência

A frequência representa a quantidade de pedidos distintos realizados pelo cliente:

```sql
COUNT(DISTINCT id)
```

O identificador `id` corresponde ao pedido.

### 3.3 Ticket médio

O ticket médio é calculado por:

```text
faturamento_total / frequencia
```

A divisão utiliza `NULLIF` para evitar divisão por zero.

O resultado apresentado é arredondado para duas casas decimais.

### 3.4 Diversidade de categorias

A diversidade representa a quantidade de categorias distintas compradas pelo cliente.

O relacionamento utilizado é:

```text
orders
  ↓
order_items
  ↓
product_variants
  ↓
products
  ↓
categories
```

A métrica utiliza:

```sql
COUNT(DISTINCT category_id)
```

Assim, a análise mede categorias diferentes e não quantidade de produtos ou quantidade de itens.

---

## 4. Tratamento da diversidade

A diversidade é associada às métricas gerais dos clientes utilizando `LEFT JOIN`.

Quando não existe correspondência, é utilizado:

```sql
COALESCE(diversidade_categorias, 0)
```

Isso mantém o cliente na análise e representa sua diversidade como zero.

---

## 5. Parte 2 — Top 10 clientes

A seleção dos Top 10 segue dois critérios.

### Primeiro filtro

Somente clientes com pelo menos 13 categorias distintas participam do ranking:

```sql
WHERE diversidade_categorias >= 13
```

### Ordenação

Os clientes são ordenados pelo maior ticket médio:

```sql
ORDER BY
    ticket_medio DESC,
    customer_id
```

O `customer_id` funciona como critério de desempate.

### Limite

São selecionados:

```sql
LIMIT 10
```

Portanto, o grupo final contém os 10 clientes com maior ticket médio entre aqueles que compraram pelo menos 13 categorias distintas.

---

## 6. Parte 3 — Categoria mais comprada pelo Top 10

Após identificar o grupo Top 10, a análise retorna novamente aos pedidos e itens comprados por esses clientes.

O relacionamento utilizado é:

```text
Top 10 clientes
      ↓
orders
      ↓
order_items
      ↓
product_variants
      ↓
products
      ↓
categories
```

A quantidade de produtos/itens por categoria é calculada utilizando:

```sql
SUM(oi.quantity)
```

As categorias são ordenadas pela maior quantidade total de itens comprados.

Assim, a métrica responde:

> Qual categoria possui a maior quantidade de itens comprados pelo grupo Top 10?

A análise não utiliza faturamento da categoria como critério nessa etapa.

---

## 7. Critérios de ranking

A lógica do ranking é consistente entre as partes.

Na seleção do Top 10, o ticket médio é utilizado como principal critério.

Na etapa de apresentação, o ticket médio pode ser arredondado para duas casas decimais.

Para ordenar o ranking, o valor não arredondado pode ser utilizado, evitando empates artificiais causados pelo arredondamento.

---

## 8. Principais métricas

| Métrica | Definição |
|---|---|
| `faturamento_total` | Soma do valor total dos pedidos do cliente |
| `frequencia` | Quantidade de pedidos distintos |
| `ticket_medio` | Faturamento total dividido pela frequência |
| `diversidade_categorias` | Quantidade de categorias distintas compradas |
| `quantidade_itens_categoria` | Soma das quantidades compradas por categoria |

---

## 9. Decisões técnicas

### `COUNT(DISTINCT id)`

Utilizado para representar a frequência por pedidos distintos.

### `COUNT(DISTINCT category_id)`

Utilizado para medir diversidade de categorias, evitando contar repetidamente a mesma categoria.

### `NULLIF`

Utilizado no cálculo do ticket médio para evitar divisão por zero.

### `COALESCE`

Utilizado para representar diversidade ausente como zero e preservar clientes na análise.

### `LEFT JOIN`

Utilizado na associação da diversidade às métricas gerais para evitar a perda de clientes sem correspondência na agregação.

### `SUM(oi.quantity)`

Utilizado na Parte 3 porque o objetivo é identificar a categoria com maior quantidade de itens comprados pelo Top 10.

---

## 10. Validação lógica

A estrutura da Q4 foi avaliada considerando:

- cálculo de faturamento;
- cálculo de frequência;
- cálculo de ticket médio;
- cálculo de diversidade;
- filtro de clientes com pelo menos 13 categorias;
- ranking dos Top 10;
- identificação da categoria mais comprada;
- proteção contra divisão por zero;
- tratamento de ausência de diversidade.

A lógica está consistente com o objetivo da análise.

---

## 11. Observação sobre a estrutura SQL

A análise repete parte das CTEs entre as diferentes partes da questão.

Essa repetição não compromete o resultado e mantém cada parte relativamente independente e auditável.

Uma versão futura poderia centralizar as CTEs em uma estrutura comum, caso fosse necessário reduzir repetição e facilitar manutenção.

Para o escopo atual, a estrutura existente foi mantida.

---

## 12. Limites da análise

A Q4 responde às métricas e critérios definidos na própria questão.

Ela não deve ser interpretada como uma análise completa de Customer Lifetime Value, segmentação RFM ou análise de rentabilidade.

O foco é:

```text
Valor
+
Frequência
+
Diversidade
+
Ranking
+
Categoria mais comprada
```

---

## 13. Status

**Q4 — ANÁLISE DE CLIENTES CONCLUÍDA E VALIDADA**

Fluxo final:

```text
Todos os clientes
      ↓
Métricas
      ↓
Diversidade ≥ 13 categorias
      ↓
Ranking por ticket médio
      ↓
Top 10
      ↓
Itens comprados por categoria
      ↓
Categoria mais comprada
```

A Q4 está tecnicamente consistente dentro do escopo analisado.
