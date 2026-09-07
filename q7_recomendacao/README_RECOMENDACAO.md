# Q7 — Sistema de Recomendação

## 1. Objetivo

Construir um sistema de recomendação baseado na similaridade de comportamento de compra dos clientes.

Produto de referência: **Motor de Popa 1949** (`product_id = 180`).

Objetivo: identificar os **5 produtos mais similares** ao produto de referência utilizando **Cosine Similarity**.

---

## 2. Regras da questão

1. Construir uma matriz **Cliente × Produto**.
2. Linhas = `customer_id`.
3. Colunas = `product_id`.
4. `1` = cliente comprou o produto.
5. `0` = cliente não comprou.
6. Ignorar a quantidade comprada.
7. Calcular similaridade produto × produto.
8. Utilizar **Cosine Similarity**.
9. Usar o **Motor de Popa 1949** como referência.
10. Excluir o próprio produto do ranking.
11. Retornar os 5 produtos mais similares.

---

## 3. Produto de referência

Resultado validado:

| Campo | Valor |
|---|---:|
| `product_id` | 180 |
| Produto | Motor de Popa 1949 |
| Variantes | 3 |

### Variantes

| `product_variant_id` | SKU |
|---:|---|
| 364 | LHN-132290 |
| 365 | LHN-830083 |
| 366 | LHN-581742 |

O produto de referência foi considerado por meio de suas três variantes.

---

## 4. Clientes compradores

O **Motor de Popa 1949 foi comprado por 397 clientes distintos**.

A quantidade comprada não participa da matriz.

Exemplos de clientes com múltiplas compras demonstraram por que a matriz precisa usar presença/ausência:

```text
customer_id 19 → 2 pedidos / 17 unidades
customer_id 38 → 2 pedidos / 14 unidades
customer_id 66 → 2 pedidos / 13 unidades
```

Na matriz, todos esses casos representam simplesmente:

```text
comprou = 1
```

---

## 5. Universo da matriz

Foram identificados:

- **2.000 clientes**
- **500 produtos**
- **135.508 combinações distintas cliente × produto com compra**

A matriz conceitual possui:

```text
2.000 × 500 = 1.000.000 células
```

A ocupação positiva é de aproximadamente **13,55%**.

Por isso, a implementação trabalha com as relações distintas de compra, evitando materializar desnecessariamente toda a matriz no terminal.

---

## 6. Base binária

A relação lógica utilizada é:

```sql
SELECT DISTINCT
    o.customer_id,
    p.id AS product_id
FROM public.orders o
JOIN public.order_items oi
    ON oi.order_id = o.id
JOIN public.product_variants pv
    ON pv.id = oi.product_variant_id
JOIN public.products p
    ON p.id = pv.product_id;
```

O `DISTINCT` garante que várias compras do mesmo produto pelo mesmo cliente sejam tratadas como uma única presença.

Foram encontrados exemplos como:

```text
customer_id | product_id | linhas_compra
------------+------------+--------------
601         | 335        | 5
622         | 345        | 5
1023        | 432        | 5
```

Isso confirma a necessidade de reduzir múltiplas ocorrências para `1`.

---

## 7. Cosine Similarity

A similaridade entre dois produtos A e B é:

```text
Cosine(A,B) =
clientes_em_comum
-------------------------------
√(clientes_A × clientes_B)
```

Onde:

- `clientes_em_comum` = clientes que compraram ambos;
- `clientes_A` = clientes que compraram o produto de referência;
- `clientes_B` = clientes que compraram o produto candidato.

Para o Motor de Popa 1949:

```text
clientes_A = 397
```

O SQL final calcula essa quantidade dinamicamente, evitando um valor fixo na fórmula.

---

## 8. Validação da interseção

Antes do ranking final, foi validada a quantidade de clientes em comum com o produto de referência:

| Produto | Clientes em comum |
|---|---:|
| Motor de Popa 5331 | 106 |
| Cabo Náutico 2105 | 103 |
| Vela Mestra 1913 | 100 |
| Cabo Náutico 9048 | 99 |
| GPS Plotter 6249 | 98 |

A etapa confirmou a correta identificação dos clientes compartilhados.

---

## 9. Registro `NAO INFORMADO`

Durante a análise, `product_id = 357`, com nome `NAO INFORMADO`, apareceu entre os candidatos.

O registro foi validado e possui:

- 431 variantes;
- 431 linhas de venda;
- 2.272 unidades vendidas.

Como o enunciado não determina sua exclusão, ele não foi removido artificialmente do cálculo.

Ele representa, entretanto, uma **limitação de qualidade dos dados**, pois o nome não identifica um produto comercial utilizável.

O registro não entrou no TOP 5 final.

---

## 10. Resultado final

| Ranking | Product ID | Produto | Clientes em comum | Clientes do produto | Cosine Similarity |
|---:|---:|---|---:|---:|---:|
| 1 | 389 | **Motor de Popa 5331** | 106 | 430 | **0,2566** |
| 2 | 295 | **Cabo Náutico 2105** | 103 | 407 | **0,2562** |
| 3 | 75 | **Vela Mestra 1913** | 100 | 385 | **0,2558** |
| 4 | 337 | **Cabo Náutico 9048** | 99 | 431 | **0,2393** |
| 5 | 55 | **GPS Plotter 6249** | 98 | 428 | **0,2377** |

### Interpretação

Para clientes que compraram o **Motor de Popa 1949**, os cinco produtos com maior similaridade de comportamento de compra foram:

1. Motor de Popa 5331
2. Cabo Náutico 2105
3. Vela Mestra 1913
4. Cabo Náutico 9048
5. GPS Plotter 6249

A Cosine Similarity mede proximidade dos padrões de compra dos clientes. Ela não representa, por si só, causalidade ou complementaridade comercial.

---

## 11. Arquivo SQL

A implementação está em:

```text
q7_recomendacao/
└── 01_recomendacao.sql
```

O arquivo foi executado diretamente no PostgreSQL e reproduziu o resultado validado.

A versão final calcula dinamicamente a quantidade de clientes do produto de referência, eliminando o `397` hardcoded da fórmula.

---

## 12. Fluxo da solução

```text
Pedidos
   ↓
Itens de pedido
   ↓
Variantes
   ↓
Produtos
   ↓
Cliente × Produto
   ↓
Presença / ausência
   ↓
Interseção de clientes
   ↓
Cosine Similarity
   ↓
Ranking
   ↓
TOP 5
```

---

## 13. Conclusão

A Q7 foi concluída utilizando uma abordagem de **filtragem colaborativa baseada em itens (item-based collaborative filtering)**.

A solução foi validada passo a passo e o SQL final reproduziu o TOP 5 esperado.

### Status

**Q7 — Sistema de Recomendação: CONCLUÍDA**

Arquivo executável: `01_recomendacao.sql`
