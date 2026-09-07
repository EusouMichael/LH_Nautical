# Q2 — Schema PostgreSQL

## 1. Objetivo

A Q2 tem como objetivo analisar a estrutura dos arquivos CSV, identificar os tipos lógicos das colunas e gerar um `schema.sql` compatível com PostgreSQL.

O processo foi estruturado para separar:

1. inspeção dos CSVs;
2. análise dos tipos identificados;
3. definição das regras de tipagem;
4. geração do schema PostgreSQL;
5. validação final do schema.

> **Escopo:** a Q2 define a estrutura e os tipos das tabelas. Não realiza limpeza, correção, preenchimento, remoção ou normalização dos dados.

---

## 2. Fluxo da Q2

```text
data/raw/*.csv
      │
      ▼
01_inspecao_schema.py
      │
      ▼
inspecao_schema.csv
      │
      ├──────────────► 02_analise_tipos.py
      │
      │
      ▼
regras_tipagem.md
      │
      ▼
02_gerar_schema.py
      │
      ▼
schema.sql
      │
      ▼
03_validar_schema.py
      │
      ▼
Schema validado
```

---

## 3. Arquivos da Q2

| Arquivo | Função |
|---|---|
| `01_inspecao_schema.py` | Inspeciona os CSVs e identifica os tipos lógicos |
| `02_analise_tipos.py` | Analisa a distribuição dos tipos e identifica colunas relevantes |
| `regras_tipagem.md` | Documenta as regras utilizadas na tipagem |
| `02_gerar_schema.py` | Gera o `schema.sql` para PostgreSQL |
| `03_validar_schema.py` | Valida tabelas, colunas e tipos críticos |
| `inspecao_schema.csv` | Resultado estruturado da inspeção |
| `schema.sql` | Schema PostgreSQL gerado |

---

## 4. Inspeção dos CSVs

O `01_inspecao_schema.py` realiza a leitura dos arquivos CSV e registra, para cada coluna:

- tabela;
- nome da coluna;
- tipo identificado;
- quantidade de linhas;
- quantidade de valores nulos.

A identificação não depende exclusivamente do dtype de uma biblioteca. São consideradas características do nome da coluna e dos valores encontrados.

### Tipos lógicos identificados

- `bool`
- `date`
- `timestamp`
- `int`
- `float`
- `object`

O resultado é salvo em:

```text
q2_schema/inspecao_schema.csv
```

---

## 5. Regras de identificação

### 5.1 Booleanos

São identificadas colunas como:

```text
is_active
is_primary
is_preferred
```

Também são reconhecidos valores booleanos equivalentes, como:

```text
true / false
t / f
yes / no
1 / 0
```

### 5.2 Datas

Campos explicitamente definidos como datas:

```text
hire_date
termination_date
```

recebem o tipo lógico `date`.

### 5.3 Timestamps

Colunas cujo nome termina com `_at` são identificadas como `timestamp`.

Exemplos:

```text
created_at
updated_at
placed_at
paid_at
```

### 5.4 Identificadores numéricos

Colunas chamadas `id` ou terminadas em `_id` podem ser identificadas como inteiros quando seus valores representam inteiros.

Exemplos:

```text
customer_id
product_id
category_id
salesperson_id
```

### 5.5 Identificadores textuais

Alguns campos devem permanecer como texto mesmo quando possuem aparência numérica.

Exemplos:

```text
barcode_ean
ncm_code
cpf
cnpj
tax_id
phone
postal_code
sku
supplier_sku
order_number
po_number
return_number
```

Essa regra evita transformar códigos identificadores em números.

### 5.6 Números

Quando todos os valores não nulos representam inteiros, o tipo lógico é `int`.

Quando representam números decimais, o tipo lógico é `float`.

### 5.7 Texto

Quando nenhuma das regras anteriores é satisfeita, a coluna é identificada como `object`.

---

## 6. Regras de tipagem PostgreSQL

A conversão para PostgreSQL segue:

| Tipo lógico | PostgreSQL |
|---|---|
| `int` | `INTEGER` |
| `bool` | `BOOLEAN` |
| `float` | `NUMERIC` |
| `object` | `TEXT` |
| `date` | `DATE` |
| `timestamp` | `TIMESTAMP` |

### Regra especial para identificadores

Uma coluna identificada como `float` pode ser convertida para `INTEGER` quando seu nome for `id` ou terminar em `_id`.

Isso trata o caso em que uma coluna originalmente inteira foi interpretada como decimal devido à presença de valores nulos.

### Regra para códigos

Códigos e identificadores textuais permanecem como:

```text
TEXT
```

mesmo que contenham somente números.

### Regra para valores financeiros

Valores monetários e decimais utilizam:

```text
NUMERIC
```

para preservar precisão decimal no PostgreSQL.

---

## 7. Valores nulos

A Q2 não realiza tratamento de qualidade dos dados.

Valores ausentes são mantidos como `NULL`.

Nenhuma coluna é removida apenas porque possui valores nulos.

### Coluna 100% nula

A coluna:

```text
stock_levels.reorder_point
```

possui 100% dos valores nulos, mas permanece no schema.

Essa decisão segue o princípio de preservar a estrutura original dos dados.

---

## 8. Geração do schema

O `02_gerar_schema.py` utiliza o arquivo:

```text
inspecao_schema.csv
```

como entrada.

Para cada tabela encontrada, gera uma instrução:

```sql
CREATE TABLE IF NOT EXISTS ...
```

O resultado é salvo em:

```text
q2_schema/schema.sql
```

O script também cria o schema:

```sql
CREATE SCHEMA IF NOT EXISTS public;
```

A geração utiliza as regras de tipagem definidas no próprio processo da Q2.

---

## 9. Validação

O `03_validar_schema.py` realiza a validação final comparando o conteúdo esperado da inspeção com o schema gerado.

São verificados:

### Quantidade de tabelas

```text
24 tabelas
```

### Quantidade de colunas

```text
212 colunas
```

### Colunas faltantes

A validação verifica se todas as colunas presentes na inspeção também existem no schema.

### Tipos críticos

São verificadas regras específicas para campos como:

```text
categories.parent_category_id
orders.salesperson_id
product_variants.barcode_ean
products.ncm_code
orders.total
orders.subtotal
orders.discount_amount
payments.amount
orders.created_at
orders.placed_at
orders.updated_at
brands.created_at
brands.updated_at
addresses.is_primary
```

### Coluna 100% nula

Também é validada a permanência de:

```text
stock_levels.reorder_point
```

---

## 10. Resultado da Q2

A validação final foi concluída com sucesso.

```text
24 tabelas
212 colunas
0 colunas faltantes
tipos críticos validados
coluna 100% nula preservada
```

### Status

**Q2 — SCHEMA VALIDADO COM SUCESSO**

---

## 11. Decisões técnicas importantes

### Não depender apenas do dtype

O tipo de uma coluna não é determinado exclusivamente pelo tipo inferido automaticamente.

O nome e o significado aparente do campo também são considerados.

### Preservar códigos como texto

Campos como CPF, CNPJ, CEP, SKU e códigos fiscais não devem ser tratados como números apenas porque seus valores possuem caracteres numéricos.

### Preservar precisão financeira

Campos financeiros utilizam `NUMERIC`.

### Não alterar os dados

A Q2 é uma etapa estrutural.

Não foram realizadas:

- correções;
- preenchimentos;
- remoções;
- normalizações;
- transformações dos valores.

---

## 12. Pontos de atenção para etapas futuras

A Q2 está encerrada dentro do seu escopo.

O `schema.sql` representa a estrutura e a tipagem das tabelas. Elementos adicionais de modelagem, relacionamento, constraints, chaves e regras de negócio não fazem parte do objetivo definido para esta etapa.

Também foi identificada uma pequena redundância na função de conversão de `float` do `02_gerar_schema.py`. Ela não compromete o resultado atual e, por isso, não foi alterada durante a conclusão da Q2.

---

## 13. Conclusão

A Q2 estabeleceu uma camada estruturada entre os CSVs brutos e o PostgreSQL:

```text
CSV
 ↓
Inspeção
 ↓
Identificação de tipos
 ↓
Regras de tipagem
 ↓
Geração do schema
 ↓
Validação
```

O resultado final foi um schema PostgreSQL com:

- **24 tabelas**
- **212 colunas**
- tipagem definida por regras;
- preservação de campos nulos;
- validação de tipos críticos;
- validação de completude estrutural.

**Status final: CONCLUÍDA E VALIDADA.**
