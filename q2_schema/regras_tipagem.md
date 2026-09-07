# Q2 — Regras de Tipagem PostgreSQL

## Objetivo

Definir as regras utilizadas pelo gerador de schema para converter
os tipos identificados nos arquivos CSV em tipos compatíveis com PostgreSQL.

---

## 1. Tipos básicos

| Tipo Pandas | PostgreSQL | Regra |
|---|---|---|
| int64 | INTEGER | Inteiros sem casas decimais |
| bool | BOOLEAN | Valores booleanos |
| float64 | NUMERIC | Valores decimais/financeiros |
| object | TEXT | Textos e códigos |

---

## 2. Float64 representando identificadores

Uma coluna `float64` não deve ser automaticamente considerada
um campo decimal.

Quando o nome da coluna indicar um identificador, o tipo deverá
ser convertido para `INTEGER`.

Exemplos:

- `parent_category_id`
- `salesperson_id`
- `reference_id`
- `employee_id`

Motivo:

O Pandas pode converter uma coluna inteira para `float64`
quando existem valores nulos (`NaN`).

---

## 3. Campos financeiros

Campos que representam valores monetários ou valores decimais
de negócio deverão utilizar `NUMERIC`.

Exemplos:

- `total`
- `subtotal`
- `discount_amount`
- `amount`
- `sale_price`
- `cost_price`
- `unit_price`
- `line_total`
- `total_refund_amount`

O objetivo é preservar precisão decimal no PostgreSQL.

---

## 4. Campos temporais

Colunas identificadas semanticamente como datas ou timestamps
deverão ser convertidas para tipos temporais do PostgreSQL,
mesmo quando o Pandas identificar o campo como `object`.

### TIMESTAMP

Campos que representam data e hora:

- `created_at`
- `updated_at`
- `placed_at`
- `occurred_at`
- `received_at`
- `issued_at`
- `paid_at`
- `expected_delivery_at`

### DATE

Campos que representam somente uma data:

- `hire_date`
- `termination_date`

---

## 5. Campos textuais e códigos

Campos textuais deverão utilizar `TEXT`.

Exemplos:

- nomes
- descrições
- cidades
- estados
- países
- status
- códigos alfanuméricos
- SKUs
- números de documentos
- e-mails

Mesmo que um código contenha apenas números, ele não deve
ser tratado como número quando sua finalidade for identificadora.

---

## 6. Valores nulos

Nenhuma coluna deverá ser removida por possuir valores nulos.

Os valores ausentes existentes nos CSVs serão representados
como `NULL` no banco de dados.

A Q2 não realiza limpeza ou correção dos dados.

---

## 7. Colunas 100% nulas

Colunas completamente nulas continuam fazendo parte do schema.

Exemplo:

`stock_levels.reorder_point`

Possui 100% dos valores nulos, mas deverá continuar presente
na tabela criada.

---

## 8. Princípio geral

A conversão não será baseada exclusivamente no dtype do Pandas.

A decisão deverá considerar:

1. dtype identificado;
2. nome da coluna;
3. significado aparente do campo;
4. presença de valores nulos;
5. necessidade de preservar precisão;
6. compatibilidade com PostgreSQL.

---

## 9. Escopo

Estas regras servem exclusivamente para a geração do schema.

Nenhum valor dos CSVs será:

- corrigido;
- preenchido;
- removido;
- transformado;
- normalizado.

O objetivo é somente definir a estrutura das tabelas no PostgreSQL.