from pathlib import Path
import pandas as pd
import re


# ============================================================
# CONFIGURAÇÃO
# ============================================================

BASE_DIR = Path(__file__).resolve().parents[1]

ARQUIVO_INSPECAO = BASE_DIR / "q2_schema" / "inspecao_schema.csv"
ARQUIVO_SCHEMA = BASE_DIR / "q2_schema" / "schema.sql"


# ============================================================
# LEITURA DOS ARQUIVOS
# ============================================================

print("=" * 70)
print("VALIDAÇÃO FINAL DO SCHEMA - QUESTÃO 2")
print("=" * 70)

df = pd.read_csv(ARQUIVO_INSPECAO)
sql = ARQUIVO_SCHEMA.read_text(encoding="utf-8")


# ============================================================
# EXTRAÇÃO DAS TABELAS E COLUNAS DO SCHEMA
# ============================================================

tabelas_schema = {}

padrao_tabela = re.compile(
    r'CREATE TABLE IF NOT EXISTS "([^"]+)" \((.*?)\);',
    re.DOTALL
)

blocos = padrao_tabela.findall(sql)

for tabela, bloco in blocos:

    colunas = {}

    for linha in bloco.splitlines():

        linha = linha.strip().rstrip(",")

        match = re.match(
            r'"([^"]+)"\s+([A-Z]+)',
            linha
        )

        if match:
            coluna = match.group(1)
            tipo = match.group(2)

            colunas[coluna] = tipo

    tabelas_schema[tabela] = colunas


# ============================================================
# 1. QUANTIDADE DE TABELAS
# ============================================================

print("\n===== 1. QUANTIDADE DE TABELAS =====")

tabelas_esperadas = set(df["tabela"].unique())
tabelas_encontradas = set(tabelas_schema.keys())

print(f"Tabelas esperadas: {len(tabelas_esperadas)}")
print(f"Tabelas encontradas: {len(tabelas_encontradas)}")

faltantes = tabelas_esperadas - tabelas_encontradas
extras = tabelas_encontradas - tabelas_esperadas

if not faltantes and not extras:
    print("OK - Todas as tabelas foram geradas.")
else:
    if faltantes:
        print(f"Tabelas faltantes: {sorted(faltantes)}")

    if extras:
        print(f"Tabelas extras: {sorted(extras)}")


# ============================================================
# 2. QUANTIDADE DE COLUNAS
# ============================================================

print("\n===== 2. QUANTIDADE DE COLUNAS =====")

total_esperado = len(df)

total_encontrado = sum(
    len(colunas)
    for colunas in tabelas_schema.values()
)

print(f"Colunas esperadas: {total_esperado}")
print(f"Colunas encontradas: {total_encontrado}")

if total_esperado == total_encontrado:
    print("OK - Todas as colunas foram geradas.")
else:
    print("ATENÇÃO - A quantidade de colunas não coincide.")


# ============================================================
# 3. COLUNAS FALTANTES
# ============================================================

print("\n===== 3. COLUNAS FALTANTES =====")

colunas_faltantes = []

for _, linha in df.iterrows():

    tabela = linha["tabela"]
    coluna = linha["coluna"]

    if tabela not in tabelas_schema:
        colunas_faltantes.append(
            f"{tabela}.{coluna}"
        )

    elif coluna not in tabelas_schema[tabela]:
        colunas_faltantes.append(
            f"{tabela}.{coluna}"
        )

if not colunas_faltantes:
    print("OK - Nenhuma coluna faltante.")
else:
    for coluna in colunas_faltantes:
        print(coluna)


# ============================================================
# 4. VALIDAÇÕES CRÍTICAS
# ============================================================

print("\n===== 4. VALIDAÇÕES CRÍTICAS =====")

validacoes = {
    ("categories", "parent_category_id"): "INTEGER",
    ("orders", "salesperson_id"): "INTEGER",
    ("product_variants", "barcode_ean"): "TEXT",
    ("products", "ncm_code"): "TEXT",
    ("orders", "total"): "NUMERIC",
    ("orders", "subtotal"): "NUMERIC",
    ("orders", "discount_amount"): "NUMERIC",
    ("payments", "amount"): "NUMERIC",
    ("orders", "created_at"): "TIMESTAMP",
    ("orders", "placed_at"): "TIMESTAMP",
    ("orders", "updated_at"): "TIMESTAMP",
    ("brands", "created_at"): "TIMESTAMP",
    ("brands", "updated_at"): "TIMESTAMP",
    ("addresses", "is_primary"): "BOOLEAN",
}

erros_criticos = []

for (tabela, coluna), tipo_esperado in validacoes.items():

    tipo_encontrado = tabelas_schema.get(
        tabela, {}
    ).get(coluna)

    if tipo_encontrado == tipo_esperado:

        print(
            f"OK  {tabela}.{coluna} -> {tipo_encontrado}"
        )

    else:

        print(
            f"ERRO {tabela}.{coluna} -> "
            f"esperado={tipo_esperado}, "
            f"encontrado={tipo_encontrado}"
        )

        erros_criticos.append(
            f"{tabela}.{coluna}"
        )


# ============================================================
# 5. COLUNA 100% NULA
# ============================================================

print("\n===== 5. COLUNA 100% NULA =====")

tabela = "stock_levels"
coluna = "reorder_point"

if coluna in tabelas_schema.get(tabela, {}):

    print(
        f"OK - {tabela}.{coluna} permanece no schema "
        f"como {tabelas_schema[tabela][coluna]}"
    )

else:

    print(
        f"ERRO - {tabela}.{coluna} não foi encontrada."
    )

    erros_criticos.append(
        f"{tabela}.{coluna}"
    )


# ============================================================
# RESULTADO FINAL
# ============================================================

print("\n" + "=" * 70)
print("RESULTADO DA VALIDAÇÃO")
print("=" * 70)

if (
    len(tabelas_esperadas) == len(tabelas_encontradas)
    and total_esperado == total_encontrado
    and not colunas_faltantes
    and not erros_criticos
):
    print("Q2 - SCHEMA VALIDADO COM SUCESSO")
    print("24 tabelas e 212 colunas conferidas.")
else:
    print("Q2 - ATENÇÃO: existem inconsistências.")
    print("Revise os itens indicados acima.")