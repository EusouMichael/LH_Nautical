import csv
from pathlib import Path
from datetime import datetime


# ============================================================
# CONFIGURAÇÃO
# ============================================================

BASE_DIR = Path(__file__).resolve().parents[1]

PASTA_CSV = BASE_DIR / "data" / "raw"
ARQUIVO_SAIDA = BASE_DIR / "q2_schema" / "inspecao_schema.csv"


# ============================================================
# REGRAS DE IDENTIFICAÇÃO
# ============================================================

COLUNAS_BOOLEANAS = {
    "is_active",
    "is_primary",
    "is_preferred",
}

COLUNAS_DATE = {
    "hire_date",
    "termination_date",
}

SUFIXOS_TIMESTAMP = (
    "_at",
)

IDENTIFICADORES_TEXTO = {
    "barcode_ean",
    "ncm_code",
    "cpf",
    "cnpj",
    "tax_id",
    "phone",
    "postal_code",
    "nfe_number",
    "nfe_access_key",
    "sku",
    "supplier_sku",
    "order_number",
    "po_number",
    "return_number",
}

SUFIXOS_IDENTIFICADORES = (
    "_id",
)


# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

def valor_nulo(valor):
    """
    Identifica valores vazios no CSV.
    Nenhum valor é alterado.
    """
    return valor is None or valor.strip() == ""


def todos_inteiros(valores):
    """
    Verifica se todos os valores não nulos representam inteiros.
    """
    for valor in valores:
        if valor_nulo(valor):
            continue

        try:
            numero = float(valor)

            if not numero.is_integer():
                return False

        except ValueError:
            return False

    return True


def todos_numericos(valores):
    """
    Verifica se todos os valores não nulos representam números.
    """
    encontrou_valor = False

    for valor in valores:
        if valor_nulo(valor):
            continue

        encontrou_valor = True

        try:
            float(valor)
        except ValueError:
            return False

    return encontrou_valor


def todos_booleanos(valores):
    """
    Identifica colunas compostas por valores booleanos.
    """
    valores_validos = {
        "true",
        "false",
        "t",
        "f",
        "yes",
        "no",
        "1",
        "0",
    }

    encontrou_valor = False

    for valor in valores:
        if valor_nulo(valor):
            continue

        encontrou_valor = True

        if valor.strip().lower() not in valores_validos:
            return False

    return encontrou_valor


def identificar_tipo(coluna, valores):
    """
    Identifica o tipo lógico da coluna sem utilizar Pandas.

    A decisão considera:
    1. nome da coluna;
    2. significado aparente;
    3. valores encontrados.
    """

    coluna_lower = coluna.lower()

    # --------------------------------------------------------
    # Identificadores que devem permanecer como texto
    # --------------------------------------------------------

    if (
        coluna_lower in IDENTIFICADORES_TEXTO
        or coluna_lower.endswith("_number")
        or coluna_lower.endswith("_code")
    ):
        return "object"

    # --------------------------------------------------------
    # Booleanos
    # --------------------------------------------------------

    if coluna_lower in COLUNAS_BOOLEANAS:
        return "bool"

    if todos_booleanos(valores):
        return "bool"

    # --------------------------------------------------------
    # Datas
    # --------------------------------------------------------

    if coluna_lower in COLUNAS_DATE:
        return "date"

    if coluna_lower.endswith(SUFIXOS_TIMESTAMP):
        return "timestamp"

    # --------------------------------------------------------
    # Identificadores numéricos
    # --------------------------------------------------------

    if coluna_lower == "id" or coluna_lower.endswith(SUFIXOS_IDENTIFICADORES):
        if todos_inteiros(valores):
            return "int"

    # --------------------------------------------------------
    # Números
    # --------------------------------------------------------

    if todos_inteiros(valores):
        return "int"

    if todos_numericos(valores):
        return "float"

    # --------------------------------------------------------
    # Texto
    # --------------------------------------------------------

    return "object"


# ============================================================
# LEITURA DOS CSVs
# ============================================================

print("=" * 70)
print("INSPEÇÃO DOS CSVs - QUESTÃO 2")
print("=" * 70)

arquivos = sorted(PASTA_CSV.glob("*.csv"))

print(f"\nQuantidade de arquivos encontrados: {len(arquivos)}")

if not arquivos:
    raise FileNotFoundError(
        f"Nenhum arquivo CSV encontrado em: {PASTA_CSV}"
    )


registros = []


# ============================================================
# PROCESSAMENTO
# ============================================================

for arquivo in arquivos:

    print(f"Processando: {arquivo.stem}")

    # Tentativa UTF-8 primeiro.
    # Caso o arquivo possua outra codificação, tenta Latin-1.
    try:
        arquivo_aberto = open(
            arquivo,
            "r",
            encoding="utf-8",
            newline=""
        )
        arquivo_aberto.read(1)
        arquivo_aberto.seek(0)

    except UnicodeDecodeError:
        arquivo_aberto = open(
            arquivo,
            "r",
            encoding="latin-1",
            newline=""
        )

    with arquivo_aberto as f:

        leitor = csv.reader(f)

        try:
            cabecalho = next(leitor)
        except StopIteration:
            print(f"AVISO: arquivo vazio: {arquivo.name}")
            continue

        valores_por_coluna = [[] for _ in cabecalho]

        quantidade_linhas = 0
        quantidade_nulos = [0] * len(cabecalho)

        for linha in leitor:

            quantidade_linhas += 1

            # Garante que linhas com quantidade diferente
            # de colunas não interrompam toda a inspeção.
            linha = linha[:len(cabecalho)]

            while len(linha) < len(cabecalho):
                linha.append("")

            for indice, valor in enumerate(linha):

                valores_por_coluna[indice].append(valor)

                if valor_nulo(valor):
                    quantidade_nulos[indice] += 1

        # ----------------------------------------------------
        # Registra cada coluna
        # ----------------------------------------------------

        for indice, coluna in enumerate(cabecalho):

            valores = valores_por_coluna[indice]

            tipo_identificado = identificar_tipo(
                coluna,
                valores
            )

            registros.append({
                "tabela": arquivo.stem,
                "coluna": coluna,
                "tipo_identificado": tipo_identificado,
                "linhas": quantidade_linhas,
                "nulos": quantidade_nulos[indice],
            })


# ============================================================
# GERAÇÃO DO RELATÓRIO
# ============================================================

with open(
    ARQUIVO_SAIDA,
    "w",
    encoding="utf-8",
    newline=""
) as f:

    escritor = csv.DictWriter(
        f,
        fieldnames=[
            "tabela",
            "coluna",
            "tipo_identificado",
            "linhas",
            "nulos",
        ]
    )

    escritor.writeheader()
    escritor.writerows(registros)


# ============================================================
# RESULTADO
# ============================================================

print("\n" + "=" * 70)
print("INSPEÇÃO CONCLUÍDA")
print("=" * 70)

print(f"Total de tabelas analisadas: {len(arquivos)}")
print(f"Total de colunas analisadas: {len(registros)}")
print(f"Arquivo gerado: {ARQUIVO_SAIDA}")