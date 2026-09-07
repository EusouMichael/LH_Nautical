# Q3 — Loading dos CSVs no PostgreSQL

## 1. Objetivo

A Q3 tem como objetivo realizar o carregamento dos 24 arquivos CSV presentes em `data/raw` para as respectivas tabelas do PostgreSQL.

O processo foi desenvolvido para realizar uma carga inicial segura, evitando duplicações e protegendo a transação em caso de erro.

---

## 2. Fluxo da Q3

```text
24 arquivos CSV
      │
      ▼
Verificação dos arquivos
      │
      ▼
Conexão PostgreSQL
      │
      ▼
Verificação da tabela
      │
      ▼
Contagem de registros no CSV
      │
      ▼
Contagem de registros no banco
      │
      ├── Quantidades iguais
      │       ↓
      │   Não recarrega
      │
      ├── Banco possui registros diferentes
      │       ↓
      │   Interrompe a carga
      │
      └── Tabela vazia
              ↓
          COPY CSV
              │
              ▼
           COMMIT
```

---

## 3. Arquivo principal

### `01_load_csvs.py`

O script é responsável por todo o processo de loading.

Principais responsabilidades:

- localizar os CSVs;
- verificar a quantidade esperada de arquivos;
- conectar ao PostgreSQL;
- verificar a existência das tabelas;
- comparar quantidade de registros;
- executar a carga;
- evitar duplicações;
- controlar a transação;
- realizar `COMMIT` ou `ROLLBACK`;
- apresentar o resultado da execução.

---

## 4. Configuração

A pasta dos dados é determinada de forma relativa ao projeto:

```python
BASE_DIR = Path(__file__).resolve().parents[1]
PASTA_CSV = BASE_DIR / "data" / "raw"
```

A conexão utiliza:

```text
Host: localhost
Porta: 5432
Banco: lh_nautical
Usuário: postgres
```

A senha não fica armazenada no código. Ela é solicitada durante a execução.

---

## 5. Validação dos arquivos

O script procura todos os arquivos:

```text
data/raw/*.csv
```

A quantidade esperada é:

```text
24 CSVs
```

Se a quantidade encontrada for diferente de 24, a execução é interrompida.

Isso evita iniciar uma carga incompleta sem que a ausência de arquivos seja percebida.

---

## 6. Correspondência CSV → tabela

A tabela PostgreSQL é determinada pelo nome do arquivo:

```text
orders.csv
    ↓
orders

customers.csv
    ↓
customers
```

O script utiliza:

```python
tabela = arquivo.stem
```

Essa convenção depende da correspondência entre os nomes dos arquivos CSV e das tabelas PostgreSQL.

---

## 7. Verificação da tabela

Antes da carga, o script consulta o `information_schema.tables` para verificar se a tabela correspondente existe no schema `public`.

Caso a tabela não exista, a execução é interrompida com erro.

Isso evita tentar carregar dados em uma tabela que não foi criada pelo processo da Q2.

---

## 8. Proteção contra duplicação

Antes de executar o `COPY`, o script calcula:

```text
Quantidade de registros no CSV
        ×
Quantidade de registros no banco
```

### Caso 1 — quantidades iguais

Se:

```text
registros no banco = registros no CSV
```

a carga não é executada.

O script informa que a quantidade já corresponde ao CSV e evita uma nova inserção.

### Caso 2 — banco possui registros diferentes

Se a tabela possui registros, mas a quantidade não corresponde ao CSV, a execução é interrompida.

Essa decisão evita adicionar dados potencialmente duplicados a uma tabela que já possui conteúdo.

### Caso 3 — tabela vazia

Quando a tabela possui zero registros, o CSV é carregado normalmente.

---

## 9. Método de carga

A carga utiliza o comando PostgreSQL:

```sql
COPY public.<tabela>
FROM STDIN
WITH (
    FORMAT CSV,
    HEADER TRUE,
    NULL ''
);
```

O `COPY` é utilizado para realizar a carga em massa dos arquivos CSV.

A estratégia é apropriada para a carga inicial do conjunto de dados.

---

## 10. Segurança dos identificadores SQL

Os nomes das tabelas são tratados utilizando `psycopg2.sql.Identifier`.

Isso evita a concatenação direta de nomes de tabelas nas consultas SQL e fornece uma forma apropriada de trabalhar com identificadores dinâmicos.

---

## 11. Controle transacional

Todas as cargas da execução são realizadas dentro de uma transação.

### Sucesso

Se todos os arquivos forem processados sem erro:

```text
COMMIT
```

As alterações são confirmadas.

### Erro

Se ocorrer qualquer exceção:

```text
ROLLBACK
```

As alterações da execução são desfeitas.

Isso evita deixar a execução em um estado parcialmente confirmado.

---

## 12. Resultado da execução

O script mantém contadores para:

```text
Arquivos carregados
Arquivos já carregados
Total de arquivos processados
```

Isso permite acompanhar o resultado da execução.

Durante a construção do projeto, a carga foi realizada com sucesso e posteriormente as tabelas foram utilizadas nas etapas analíticas seguintes.

---

## 13. Limitações conhecidas

A proteção contra duplicação utiliza principalmente a quantidade de registros como critério.

Exemplo:

```text
CSV  = 2.000 registros
Banco = 2.000 registros
```

Nesse cenário, o script considera que a tabela já foi carregada.

Essa comparação não garante, isoladamente, que todos os registros sejam idênticos.

Uma implementação de produção poderia utilizar mecanismos adicionais de validação, como:

- comparação de chaves;
- checksums;
- hashes;
- comparação de conteúdo;
- controle de versão da carga.

Essa melhoria não foi necessária para o escopo atual da Q3.

---

## 14. Relação com a Q2

A Q3 depende do schema criado na Q2.

O fluxo entre as etapas é:

```text
Q2
Schema PostgreSQL
      ↓
Q3
Carga dos CSVs
      ↓
Banco populado
      ↓
Q4+
Análises SQL
```

Portanto, a existência das tabelas é verificada antes de cada carga.

---

## 15. Decisões técnicas

### `COPY`

Escolhido para carga em massa dos CSVs.

### `getpass`

Utilizado para não armazenar a senha do PostgreSQL no código.

### `sql.Identifier`

Utilizado para trabalhar com nomes de tabelas dinamicamente.

### `COMMIT / ROLLBACK`

Utilizados para garantir consistência transacional.

### Proteção contra duplicação

Implementada para impedir uma segunda carga quando a quantidade de registros já corresponde ao CSV.

---

## 16. Status

**Q3 — LOADING CONCLUÍDO**

Resultado:

```text
24 arquivos CSV processados
Tabelas PostgreSQL previamente criadas
Carga realizada com proteção contra duplicação
Controle transacional implementado
```

A Q3 está concluída dentro do escopo definido para o carregamento inicial dos dados.
