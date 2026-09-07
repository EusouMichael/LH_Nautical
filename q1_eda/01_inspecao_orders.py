import pandas as pd
from pathlib import Path

# Caminho do arquivo de origem
arquivo = Path(__file__).resolve().parents[1] / "data" / "raw" / "orders.csv"

# Leitura do CSV
orders = pd.read_csv(arquivo)

# Informações básicas
print("\n===== DIMENSÕES =====")
print(f"Linhas: {orders.shape[0]}")
print(f"Colunas: {orders.shape[1]}")

# Nome das colunas
print("\n===== COLUNAS =====")
for coluna in orders.columns:
    print(coluna)

# Tipos de dados
print("\n===== TIPOS DE DADOS =====")
print(orders.dtypes)

# Primeiras linhas
print("\n===== PRIMEIRAS 5 LINHAS =====")
print(orders.head())
