# Q6 — Previsão de Demanda

## 1. Objetivo

A Q6 tem como objetivo gerar a previsão de demanda para o primeiro trimestre de 2026 do produto **Bússola de Bordo 702**, utilizando uma **média móvel dos últimos 3 meses de vendas**.

O período de treinamento considera dados até **31/12/2025** e o período de teste corresponde ao primeiro trimestre de 2026.

---

## 2. Escopo definido pelo desafio

A questão determina:

- período de treino até 31/12/2025;
- período de teste no primeiro trimestre de 2026;
- previsão mensal;
- utilização de média móvel dos últimos 3 meses;
- comparação entre previsão e realizado utilizando **MAE (Mean Absolute Error)**;
- consideração exclusiva do produto **Bússola de Bordo 702**.

---

## 3. Representação do produto no dataset

Durante a validação da Q6 foi identificado que o produto comercial **Bússola de Bordo 702** aparece em dois registros da tabela `products`:

| `product_id` | Produto | Quantidade de variantes |
|---:|---|---:|
| 74 | Bússola de Bordo 702 | 2 |
| 240 | Bússola de Bordo 702 | 1 |

As três variantes identificadas foram:

| `product_id` | `product_variant_id` | SKU |
|---:|---:|---|
| 74 | 147 | LHN-677223 |
| 74 | 148 | LHN-795790 |
| 240 | 486 | LHN-304058 |

Todas as três variantes possuem vendas.

| `product_variant_id` | Linhas de venda | Unidades vendidas |
|---:|---:|---:|
| 147 | 159 | 882 |
| 148 | 171 | 878 |
| 486 | 142 | 783 |
| **Total** | **472** | **2.543** |

Dessa forma, a previsão consolida as vendas das três variantes que representam o produto comercial solicitado.

No SQL, essa representação é aplicada por:

```sql
WHERE pv.product_id IN (74, 240)
```

---

## 4. Construção da série histórica

As vendas são agregadas mensalmente utilizando:

```sql
DATE_TRUNC('month', o.placed_at)
```

e:

```sql
SUM(oi.quantity)
```

O período de treinamento é limitado a dados anteriores a janeiro de 2026:

```sql
o.placed_at < DATE '2026-01-01'
```

A série histórica consolidada próxima ao período de previsão foi validada diretamente no PostgreSQL:

| Mês | Unidades vendidas |
|---|---:|
| Jul/2025 | 19 |
| Ago/2025 | 23 |
| Set/2025 | 31 |
| **Out/2025** | **34** |
| **Nov/2025** | **60** |
| **Dez/2025** | **22** |

---

## 5. Método de previsão

O método utilizado é uma **média móvel recursiva de 3 meses**.

A previsão de janeiro utiliza os três últimos meses históricos.

A partir de fevereiro, a previsão anterior passa a participar do cálculo.

Em março, as previsões de janeiro e fevereiro também são utilizadas.

Fluxo:

```text
Histórico real
     ↓
Previsão Jan/2026
     ↓
Previsão Fev/2026
     ↓
Previsão Mar/2026
```

---

## 6. Previsão de janeiro de 2026

São utilizados:

```text
Outubro/2025 = 34
Novembro/2025 = 60
Dezembro/2025 = 22
```

Fórmula:

```text
(34 + 60 + 22) / 3
= 116 / 3
= 38,6667
≈ 38,67
```

Resultado:

```text
Jan/2026 = 38,67 unidades
```

---

## 7. Previsão de fevereiro de 2026

A previsão de fevereiro utiliza:

```text
Novembro/2025 = 60
Dezembro/2025 = 22
Previsão Jan/2026 = 38,67
```

Fórmula:

```text
(60 + 22 + 38,67) / 3
= 120,67 / 3
≈ 40,22
```

Resultado:

```text
Fev/2026 = 40,22 unidades
```

---

## 8. Previsão de março de 2026

A previsão de março utiliza:

```text
Dezembro/2025 = 22
Previsão Jan/2026 = 38,67
Previsão Fev/2026 = 40,22
```

Fórmula:

```text
(22 + 38,67 + 40,22) / 3
= 100,89 / 3
≈ 33,63
```

Resultado:

```text
Mar/2026 = 33,63 unidades
```

---

## 9. Resultado final da previsão

| Mês | Previsão |
|---|---:|
| Jan/2026 | **38,67** |
| Fev/2026 | **40,22** |
| Mar/2026 | **33,63** |

Os valores foram executados e validados diretamente no PostgreSQL.

---

## 10. Comparação com o realizado

Os valores reais do período de teste foram:

| Mês | Previsão | Realizado | Erro absoluto |
|---|---:|---:|---:|
| Jan/2026 | 38,67 | 79 | 40,33 |
| Fev/2026 | 40,22 | 68 | 27,78 |
| Mar/2026 | 33,63 | 60 | 26,37 |

---

## 11. Métrica de avaliação — MAE

Foi utilizado o **MAE (Mean Absolute Error / Erro Absoluto Médio)**.

Fórmula:

```text
MAE = média dos erros absolutos
```

Com os três meses:

```text
MAE = (40,33 + 27,78 + 26,37) / 3
MAE = 31,49
```

Resultado validado:

```text
MAE = 31,49 unidades
```

---

## 12. Interpretação

O modelo apresentou previsões abaixo dos valores efetivamente realizados nos três meses do período de teste.

Isso indica que, neste conjunto de teste, a média móvel de três meses **subestimou a demanda**.

O MAE de:

```text
31,49 unidades
```

significa que, em média, a previsão ficou aproximadamente 31,49 unidades distante do valor realizado, considerando o erro absoluto.

O resultado deve ser interpretado dentro do contexto do método utilizado e do curto período de teste de três meses.

---

## 13. Limitações do método

A média móvel é um baseline simples e transparente, mas possui limitações:

- reage lentamente a mudanças bruscas de demanda;
- não modela tendência explicitamente;
- não considera sazonalidade;
- não utiliza variáveis externas;
- previsões recursivas podem propagar erros;
- o período de teste possui somente três meses.

Portanto, o método é adequado como **baseline**, mas não necessariamente como modelo definitivo de planejamento de estoque.

---

## 14. Decisões técnicas

### `DATE_TRUNC`

Utilizado para consolidar as vendas por mês.

### `SUM(oi.quantity)`

Utilizado para obter a quantidade mensal vendida.

### Filtro temporal

```sql
o.placed_at < DATE '2026-01-01'
```

Garante que os dados do período de teste não sejam utilizados na construção do histórico inicial.

### Média móvel de 3 meses

Utilizada conforme a premissa do desafio.

### Previsão recursiva

As previsões calculadas passam a integrar as janelas dos meses seguintes.

### `ROUND`

Utilizado para apresentar os valores com duas casas decimais.

---

## 15. Validação da Q6

A validação foi realizada em etapas:

1. identificação dos registros do produto;
2. identificação das variantes;
3. confirmação de vendas em todas as variantes;
4. consolidação das unidades vendidas;
5. validação dos meses históricos;
6. reprodução manual da previsão de janeiro;
7. reprodução manual da previsão de fevereiro;
8. reprodução manual da previsão de março;
9. comparação com os valores realizados;
10. cálculo e validação do MAE.

A cadeia foi confirmada:

```text
Bússola de Bordo 702
        ↓
product_id 74 + 240
        ↓
3 variantes
        ↓
Out/25 = 34
Nov/25 = 60
Dez/25 = 22
        ↓
Jan/26 = 38,67
        ↓
Fev/26 = 40,22
        ↓
Mar/26 = 33,63
        ↓
MAE = 31,49
```

---

## 16. Observação sobre a identificação por nome

Durante a validação, uma consulta utilizando diretamente o nome do produto não retornou registros devido à representação/encoding dos caracteres especiais no banco/terminal.

A validação foi então realizada pelos `product_id` 74 e 240, previamente confirmados como registros do produto **Bússola de Bordo 702**.

Isso não alterou os dados nem a lógica da previsão.

---

## 17. Status

**Q6 — PREVISÃO CONCLUÍDA, VALIDADA E DOCUMENTADA**

Resultado final:

```text
Jan/2026 → 38,67
Fev/2026 → 40,22
Mar/2026 → 33,63

MAE → 31,49
```

A Q6 está encerrada dentro do escopo definido pelo desafio.
