import csv
import getpass
from io import TextIOWrapper
from pathlib import Path

import psycopg2
from psycopg2 import sql


# ============================================================
# CONFIGURAÇÃO
# ============================================================

BASE_DIR = Path(__file__).resolve().parents[1]

PASTA_CSV = BASE_DIR / "data" / "raw"

HOST = "localhost"
PORT = 5432
DATABASE = "lh_nautical"
USER = "postgres"


# ============================================================
# CONEXÃO
# ============================================================

def conectar():

    senha = getpass.getpass(
        "Senha do PostgreSQL: "
    )

    return psycopg2.connect(
        host=HOST,
        port=PORT,
        dbname=DATABASE,
        user=USER,
        password=senha
    )


# ============================================================
# CONTAGEM DE LINHAS DO CSV
# ============================================================

def contar_linhas_csv(arquivo):

    with open(
        arquivo,
        "r",
        encoding="utf-8",
        newline=""
    ) as f:

        leitor = csv.reader(f)

        # Ignora o cabeçalho
        next(leitor, None)

        return sum(1 for _ in leitor)


# ============================================================
# VERIFICAÇÃO DA TABELA
# ============================================================

def tabela_existe(cursor, tabela):

    cursor.execute(
        """
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = %s
        );
        """,
        (tabela,)
    )

    return cursor.fetchone()[0]


# ============================================================
# CONTAGEM DE REGISTROS NO POSTGRESQL
# ============================================================

def contar_registros(cursor, tabela):

    consulta = sql.SQL(
        "SELECT COUNT(*) FROM public.{}"
    ).format(
        sql.Identifier(tabela)
    )

    cursor.execute(consulta)

    return cursor.fetchone()[0]


# ============================================================
# CARREGAMENTO
# ============================================================

def carregar_csv(cursor, arquivo, tabela):

    print(f"\nProcessando: {arquivo.name}")

    # --------------------------------------------------------
    # Verifica se a tabela existe
    # --------------------------------------------------------

    if not tabela_existe(cursor, tabela):

        raise RuntimeError(
            f"Tabela não encontrada no PostgreSQL: {tabela}"
        )

    # --------------------------------------------------------
    # Conta registros do CSV
    # --------------------------------------------------------

    linhas_csv = contar_linhas_csv(arquivo)

    print(
        f"Registros no CSV: {linhas_csv}"
    )

    # --------------------------------------------------------
    # Conta registros já existentes
    # --------------------------------------------------------

    registros_banco = contar_registros(
        cursor,
        tabela
    )

    print(
        f"Registros no banco: {registros_banco}"
    )

    # --------------------------------------------------------
    # Proteção contra duplicação
    # --------------------------------------------------------

    if registros_banco == linhas_csv:

        print(
            "OK - quantidade já corresponde ao CSV. "
            "Carga não executada para evitar duplicação."
        )

        return "ja_carregado"

    # --------------------------------------------------------
    # Se houver dados diferentes no banco, interrompe
    # --------------------------------------------------------

    if registros_banco > 0:

        raise RuntimeError(
            f"A tabela '{tabela}' já possui "
            f"{registros_banco} registros, mas o CSV possui "
            f"{linhas_csv}. "
            "Carga interrompida para evitar duplicação."
        )

    # --------------------------------------------------------
    # Tabela vazia → realiza COPY
    # --------------------------------------------------------

    comando_copy = sql.SQL(
        """
        COPY public.{}
        FROM STDIN
        WITH (
            FORMAT CSV,
            HEADER TRUE,
            NULL ''
        )
        """
    ).format(
        sql.Identifier(tabela)
    )

    with open(
        arquivo,
        "r",
        encoding="utf-8",
        newline=""
    ) as f:

        cursor.copy_expert(
            comando_copy.as_string(cursor.connection),
            f
        )

    print(
        f"OK - {linhas_csv} registros carregados."
    )

    return "carregado"


# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

def main():

    print("=" * 70)
    print("LH NAUTICAL - QUESTÃO 3 - CARREGAMENTO")
    print("=" * 70)

    # --------------------------------------------------------
    # Verifica CSVs
    # --------------------------------------------------------

    arquivos = sorted(
        PASTA_CSV.glob("*.csv")
    )

    print(
        f"\nArquivos CSV encontrados: {len(arquivos)}"
    )

    if len(arquivos) != 24:

        raise RuntimeError(
            f"Esperados 24 CSVs, encontrados "
            f"{len(arquivos)}."
        )

    # --------------------------------------------------------
    # Conecta ao PostgreSQL
    # --------------------------------------------------------

    print("\nConectando ao PostgreSQL...")

    conexao = conectar()

    print("Conexão PostgreSQL: OK")

    cursor = conexao.cursor()

    # --------------------------------------------------------
    # Estatísticas
    # --------------------------------------------------------

    carregados = 0
    ja_carregados = 0

    try:

        for arquivo in arquivos:

            tabela = arquivo.stem

            resultado = carregar_csv(
                cursor,
                arquivo,
                tabela
            )

            if resultado == "carregado":

                carregados += 1

            elif resultado == "ja_carregado":

                ja_carregados += 1

        # ----------------------------------------------------
        # Commit
        # ----------------------------------------------------

        conexao.commit()

    except Exception:

        conexao.rollback()

        print(
            "\nERRO - Nenhuma alteração desta execução "
            "foi confirmada."
        )

        raise

    finally:

        cursor.close()
        conexao.close()

    # --------------------------------------------------------
    # Resultado
    # --------------------------------------------------------

    print("\n" + "=" * 70)
    print("CARREGAMENTO CONCLUÍDO")
    print("=" * 70)

    print(
        f"Arquivos carregados: {carregados}"
    )

    print(
        f"Arquivos já carregados: {ja_carregados}"
    )

    print(
        f"Total de arquivos processados: "
        f"{carregados + ja_carregados}"
    )


# ============================================================
# PONTO DE ENTRADA
# ============================================================

if __name__ == "__main__":
    main()