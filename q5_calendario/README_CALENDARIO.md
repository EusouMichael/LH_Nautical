# Q5 — Calendário e Análise por Dia da Semana

## 1. Objetivo

A Q5 tem como objetivo construir uma dimensão de calendário para o período de vendas físicas (POS), gerar uma visão de vendas diárias e calcular a média de vendas por dia da semana.

O processo foi estruturado em três camadas:

1. `dim_calendario`;
2. `vendas_diarias_pos`;
3. `media_vendas_dia_semana`.

---

## 2. Fluxo da Q5

```text
orders
   │
   │ channel = 'pos'
   ▼
Período mínimo e máximo
   │
   ▼
dim_calendario
   │
   ▼
vendas_diarias_pos
   │
   ▼
media_vendas_dia_semana
```

A dimensão de calendário garante que todos os dias do período sejam representados, inclusive aqueles sem vendas.

---

## 3. Arquivo principal

### `01_calendario.sql`

O arquivo implementa toda a lógica da Q5:

- identificação do período de análise;
- geração das datas;
- criação da dimensão calendário;
- criação da visão de vendas diárias;
- tratamento de dias sem vendas;
- cálculo das médias por dia da semana.

---

## 4. Período analisado

O período da dimensão é determinado a partir de `orders`, considerando somente vendas do canal POS:

```sql
WHERE channel = 'pos'
```

São identificadas:

```text
data_inicio = menor placed_at
data_fim    = maior placed_at
```

considerando apenas as datas das vendas POS.

---

## 5. Construção da `dim_calendario`

A dimensão é criada utilizando `generate_series`:

```sql
generate_series(
    data_inicio,
    data_fim,
    INTERVAL '1 day'
)
```

Isso gera uma sequência contínua de datas entre o início e o fim do período.

A principal vantagem dessa abordagem é manter no calendário também os dias em que não houve vendas.

---

## 6. Atributos da dimensão

A `dim_calendario` contém:

| Campo | Descrição |
|---|---|
| `data` | Data do calendário |
| `ano` | Ano da data |
| `mes` | Mês da data |
| `dia` | Dia do mês |
| `numero_dia_semana` | Número ISO do dia da semana |
| `dia_semana` | Nome do dia da semana em português |

---

## 7. Numeração ISO dos dias

A numeração dos dias utiliza:

```sql
EXTRACT(ISODOW FROM data)
```

O padrão utilizado é:

```text
1 = segunda-feira
2 = terça-feira
3 = quarta-feira
4 = quinta-feira
5 = sexta-feira
6 = sábado
7 = domingo
```

Essa padronização permite ordenar os dias da semana corretamente.

---

## 8. `vendas_diarias_pos`

A segunda camada associa o calendário às vendas POS.

O relacionamento utiliza:

```sql
FROM public.dim_calendario dc
LEFT JOIN public.orders o
```

com a data de `placed_at`.

O uso de `LEFT JOIN` é importante porque mantém todos os dias da dimensão, mesmo quando não existe venda naquele dia.

---

## 9. Dias sem vendas

Quando um dia não possui pedidos, a soma das vendas poderia resultar em `NULL`.

Para representar corretamente a ausência de vendas, é utilizado:

```sql
COALESCE(
    SUM(o.total),
    0
)
```

Assim:

```text
dia com vendas    → valor das vendas
dia sem vendas    → 0
```

Essa decisão é importante para que os dias sem movimentação participem do cálculo das médias.

---

## 10. `media_vendas_dia_semana`

A terceira camada agrupa as vendas diárias pelo número e nome do dia da semana.

São calculadas:

- quantidade de dias observados;
- vendas totais;
- média de vendas por dia.

A média utiliza:

```sql
AVG(vendas_diarias)
```

Como os dias sem vendas foram mantidos e representados por zero, eles também participam do cálculo.

---

## 11. Interpretação da média

A média representa a venda diária média observada para cada dia da semana durante o período analisado.

Exemplo conceitual:

```text
Segunda:
R$ 100
R$ 200
R$   0
```

A média considera os três dias:

```text
(R$ 100 + R$ 200 + R$ 0) / 3
= R$ 100
```

Portanto, a análise não ignora dias sem movimentação.

---

## 12. Views e objetos produzidos

A Q5 produz a seguinte estrutura:

```text
dim_calendario
        │
        ▼
vendas_diarias_pos
        │
        ▼
media_vendas_dia_semana
```

A `dim_calendario` funciona como a base temporal.

A `vendas_diarias_pos` transforma os pedidos em uma série diária.

A `media_vendas_dia_semana` consolida essa série para análise do comportamento por dia da semana.

---

## 13. Recriação dos objetos

O script utiliza comandos `DROP` antes da recriação dos objetos.

Essa estratégia permite executar novamente o SQL durante o desenvolvimento sem carregar objetos antigos ou resultados de uma execução anterior.

Para o contexto do projeto, isso proporciona reprodutibilidade da análise.

Em um ambiente de produção, uma estratégia incremental ou de atualização controlada poderia ser mais apropriada.

---

## 14. Decisões técnicas

### `generate_series`

Utilizado para criar uma sequência contínua de datas.

### `EXTRACT(ISODOW ...)`

Utilizado para obter a numeração ISO dos dias da semana.

### `LEFT JOIN`

Utilizado para preservar dias sem vendas.

### `COALESCE`

Utilizado para transformar ausência de vendas em zero.

### `AVG`

Utilizado para calcular a média diária por dia da semana.

### Canal POS

A análise considera somente registros com:

```text
channel = 'pos'
```

---

## 15. Ponto metodológico importante

A dimensão de calendário é construída antes da agregação das vendas.

Isso garante que a análise não seja baseada somente nas datas existentes na tabela `orders`.

O resultado representa o período completo:

```text
primeira data POS
        ↓
todas as datas
        ↓
última data POS
```

incluindo dias sem vendas.

---

## 16. Avaliação técnica

A estrutura da Q5 foi avaliada considerando:

- definição correta do período;
- geração contínua do calendário;
- atributos temporais;
- ordenação ISO dos dias;
- inclusão de dias sem vendas;
- tratamento de `NULL`;
- cálculo da média;
- separação das camadas;
- utilização exclusiva do canal POS.

A lógica está consistente com o objetivo da análise.

---

## 17. Status

**Q5 — CALENDÁRIO CONCLUÍDO E VALIDADO**

Fluxo final:

```text
Vendas POS
   ↓
Período mínimo/máximo
   ↓
Dimensão calendário
   ↓
Vendas diárias
   ↓
Dias sem vendas = 0
   ↓
Média por dia da semana
```

A Q5 está tecnicamente consistente dentro do escopo analisado.
