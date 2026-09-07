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


# ============================================================
# LEITURA DA INSPEÇÃO
# ============================================================

print("=" * 70)
print("ANÁLISE DOS TIPOS - QUESTÃO 2")
print("=" * 70)


if not ARQUIVO_INSPECAO.exists():
    raise FileNotFoundError(
        f"Arquivo não encontrado: {ARQUIVO_INSPECAO}"
    )


with open(
    ARQUIVO_INSPECAO,
    "r",
    encoding="utf-8",
    newline=""
) as arquivo:

    leitor = csv.DictReader(arquivo)
    registros = list(leitor)


# ============================================================
# DISTRIBUIÇÃO DOS TIPOS
# ============================================================

print("\n===== DISTRIBUIÇÃO DOS TIPOS =====")

distribuicao = {}

for registro in registros:

    tipo = registro["tipo_identificado"]

    distribuicao[tipo] = (
        distribuicao.get(tipo, 0) + 1
    )


for tipo, quantidade in sorted(
    distribuicao.items()
):
    print(f"{tipo}: {quantidade}")


# ============================================================
# COLUNAS NUMÉRICAS DECIMAIS
# ============================================================

print("\n===== COLUNAS FLOAT =====")

for registro in registros:

    if registro["tipo_identificado"] == "float":

        print(
            f"{registro['tabela']}."
            f"{registro['coluna']} "
            f"| linhas={registro['linhas']} "
            f"| nulos={registro['nulos']}"
        )


# ============================================================
# COLUNAS TEXTUAIS
# ============================================================

print("\n===== COLUNAS TEXTUAIS =====")

for registro in registros:

    if registro["tipo_identificado"] == "object":

        print(
            f"{registro['tabela']}."
            f"{registro['coluna']} "
            f"| linhas={registro['linhas']} "
            f"| nulos={registro['nulos']}"
        )


# ============================================================
# COLUNAS 100% NULAS
# ============================================================

print("\n===== COLUNAS 100% NULAS =====")

colunas_nulas = []

for registro in registros:

    linhas = int(registro["linhas"])
    nulos = int(registro["nulos"])

    if linhas > 0 and nulos == linhas:

        colunas_nulas.append(registro)


if not colunas_nulas:

    print(
        "Nenhuma coluna possui 100% "
        "de valores nulos."
    )

else:

    for registro in colunas_nulas:

        print(
            f"{registro['tabela']}."
            f"{registro['coluna']} "
            f"| nulos={registro['nulos']}"
        )


# ============================================================
# RESUMO
# ============================================================

print("\n" + "=" * 70)
print("ANÁLISE CONCLUÍDA")
print("=" * 70)

print(
    f"Total de colunas analisadas: "
    f"{len(registros)}"
)

print(
    f"Total de tipos identificados: "
    f"{len(distribuicao)}"
)

print(
    f"Colunas 100% nulas: "
    f"{len(colunas_nulas)}"
)