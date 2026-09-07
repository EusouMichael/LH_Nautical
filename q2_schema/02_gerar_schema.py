import csv
from pathlib import Path


# ============================================================
# CONFIGURAÇÃO
# ============================================================

BASE_DIR = Path(__file__).resolve().parents[1]

ARQUIVO_INSPECAO = (
    BASE_DIR
    / "q2_schema"
    / "inspecao_schema.csv"
)

ARQUIVO_SAIDA = (
    BASE_DIR
    / "q2_schema"
    / "schema.sql"
)


# ============================================================
# REGRAS DE TIPAGEM
# ============================================================

def definir_tipo_postgres(coluna, tipo_identificado):

    coluna_lower = coluna.lower()

    # --------------------------------------------------------
    # Códigos e identificadores que devem permanecer TEXT
    # --------------------------------------------------------

    if coluna_lower in {
        "barcode_ean",
        "ncm_code",
        "cpf",
        "cnpj",
        "tax_id",
        "phone",
        "postal_code",
        "sku",
        "supplier_sku",
        "nfe_number",
        "nfe_access_key",
        "order_number",
        "po_number",
        "return_number",
    }:

        return "TEXT"

    # --------------------------------------------------------
    # Booleanos
    # --------------------------------------------------------

    if tipo_identificado == "bool":
        return "BOOLEAN"

    # --------------------------------------------------------
    # Datas
    # --------------------------------------------------------

    if tipo_identificado == "date":
        return "DATE"

    if tipo_identificado == "timestamp":
        return "TIMESTAMP"

    # --------------------------------------------------------
    # Inteiros
    # --------------------------------------------------------

    if tipo_identificado == "int":
        return "INTEGER"

    # --------------------------------------------------------
    # Identificadores que eventualmente foram identificados
    # como float devido à presença de valores nulos
    # --------------------------------------------------------

    if tipo_identificado == "float":

        if (
            coluna_lower == "id"
            or coluna_lower.endswith("_id")
        ):
            return "INTEGER"

        return "NUMERIC"

    # --------------------------------------------------------
    # Decimais
    # --------------------------------------------------------

    if tipo_identificado == "float":
        return "NUMERIC"

    # --------------------------------------------------------
    # Texto
    # --------------------------------------------------------

    if tipo_identificado == "object":
        return "TEXT"

    # --------------------------------------------------------
    # Fallback
    # --------------------------------------------------------

    return "TEXT"


# ============================================================
# INÍCIO
# ============================================================

print("=" * 70)
print("GERAÇÃO DO SCHEMA POSTGRESQL - QUESTÃO 2")
print("=" * 70)


if not ARQUIVO_INSPECAO.exists():

    raise FileNotFoundError(
        f"Arquivo não encontrado: {ARQUIVO_INSPECAO}"
    )


# ============================================================
# LEITURA DA INSPEÇÃO
# ============================================================

with open(
    ARQUIVO_INSPECAO,
    "r",
    encoding="utf-8",
    newline=""
) as arquivo:

    leitor = csv.DictReader(arquivo)

    registros = list(leitor)


# ============================================================
# VALIDAÇÃO DO ARQUIVO DE INSPEÇÃO
# ============================================================

colunas_obrigatorias = {
    "tabela",
    "coluna",
    "tipo_identificado",
    "linhas",
    "nulos",
}

colunas_encontradas = set(
    registros[0].keys()
) if registros else set()


colunas_faltantes = (
    colunas_obrigatorias
    - colunas_encontradas
)


if colunas_faltantes:

    raise ValueError(
        "Colunas ausentes no arquivo de inspeção: "
        f"{sorted(colunas_faltantes)}"
    )


# ============================================================
# ORGANIZAÇÃO DAS TABELAS
# ============================================================

tabelas = []

for registro in registros:

    tabela = registro["tabela"]

    if tabela not in tabelas:
        tabelas.append(tabela)


print(f"\nTabelas encontradas: {len(tabelas)}")


# ============================================================
# GERAÇÃO DO SQL
# ============================================================

sql = []

sql.append(
    "-- =========================================================="
)

sql.append(
    "-- LH NAUTICAL - SCHEMA POSTGRESQL"
)

sql.append(
    "-- Questão 2 - Desafio Lighthouse Dados e IA"
)

sql.append(
    "-- =========================================================="
)

sql.append("")

sql.append(
    "CREATE SCHEMA IF NOT EXISTS public;"
)

sql.append("")


for tabela in tabelas:

    print(f"Gerando tabela: {tabela}")

    registros_tabela = [
        registro
        for registro in registros
        if registro["tabela"] == tabela
    ]

    sql.append(
        "-- =========================================================="
    )

    sql.append(
        f"-- TABELA: {tabela}"
    )

    sql.append(
        "-- =========================================================="
    )

    sql.append(
        f'CREATE TABLE IF NOT EXISTS "{tabela}" ('
    )

    definicoes = []

    for registro in registros_tabela:

        coluna = registro["coluna"]

        tipo_identificado = (
            registro["tipo_identificado"]
        )

        tipo_postgres = definir_tipo_postgres(
            coluna,
            tipo_identificado
        )

        definicoes.append(
            f'    "{coluna}" {tipo_postgres}'
        )

    sql.append(
        ",\n".join(definicoes)
    )

    sql.append(");")
    sql.append("")


# ============================================================
# GRAVAÇÃO
# ============================================================

ARQUIVO_SAIDA.write_text(
    "\n".join(sql),
    encoding="utf-8"
)


# ============================================================
# RESULTADO
# ============================================================

total_colunas = len(registros)

print("\n" + "=" * 70)
print("SCHEMA GERADO COM SUCESSO")
print("=" * 70)

print(f"Tabelas geradas: {len(tabelas)}")
print(f"Colunas geradas: {total_colunas}")
print(f"Arquivo: {ARQUIVO_SAIDA}")