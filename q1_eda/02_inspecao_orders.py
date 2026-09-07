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

# Estatísticas solicitadas pela Q1
print("\n===== ESTATÍSTICAS DA Q1 =====")

print(f"Data mínima (created_at): {orders['created_at'].min()}")
print(f"Data máxima (created_at): {orders['created_at'].max()}")

print(f"Valor mínimo (total): R$ {orders['total'].min():,.2f}")
print(f"Valor máximo (total): R$ {orders['total'].max():,.2f}")
print(f"Valor médio (total): R$ {orders['total'].mean():,.2f}")

# Primeiras linhas
print("\n===== PRIMEIRAS 5 LINHAS =====")
print(orders.head())