# CONTEXTO — DESAFIO LIGHTHOUSE / LH NAUTICAL

Checkpoint: 2026-08-10

## Estrutura do projeto
1-LH_NAUTICAL_CSV/
- .vscode/
- dashboard/
- data/raw/
- docs/
- q1_eda/
- q2_schema/
- q3_loading/
- q4_clientes/
- q5_calendario/
- q6_previsao/
- q7_recomendacao/

## CSVs em data/raw
24 arquivos:
addresses.csv, attributes.csv, brands.csv, categories.csv, customers.csv,
employees.csv, fiscal_invoices.csv, goods_receipt_items.csv, goods_receipts.csv,
locations.csv, order_items.csv, orders.csv, payments.csv, product_suppliers.csv,
product_variants.csv, products.csv, purchase_order_items.csv, purchase_orders.csv,
return_items.csv, returns.csv, stock_levels.csv, stock_movements.csv, suppliers.csv,
variant_attribute_values.csv.

## Status
Q1 EDA: já trabalhada.
Q2 Schema: schema criado no PostgreSQL; pasta q2_schema existe. Inspecionar seus arquivos ao retomar.
Q3 Loading: pasta q3_loading está VAZIA.

## Requisito da Q3
A Indicium exige:
- carregar todos os CSVs;
- usar obrigatoriamente Python 3;
- usar biblioteca Python para conexão/carregamento;
- não remover nulos nem corrigir caracteres especiais;
- escrever script Python respeitando o schema da questão anterior.

Os CSVs já foram carregados manualmente no PostgreSQL com \copy para validação, mas isso não substitui o entregável Python da Q3.

## PostgreSQL
Banco: lh_nautical
Schema: public
24 tabelas confirmadas.

Contagens principais:
customers 2000
products 500
product_variants 1009
orders 48998
order_items 147320
payments 53546
returns 980
employees 15
locations 6
suppliers 25
variant_attribute_values 2018

## Problemas de carga já tratados
suppliers.phone rejeitou valor 06100715800 quando integer; tipo foi ajustado para permitir telefone como identificador.
variant_attribute_values teve erro de encoding na linha 718; carga concluída com ENCODING 'LATIN1', COPY 2018.

Não fazer limpeza dos CSVs.

## Auditoria já concluída
- 24/24 tabelas presentes.
- Principais relações sem registros órfãos.
- orders sem customer: 0.
- employees sem location: 0.
- orders: 48998 registros; customer_id e created_at completos.
- orders: subtotal, discount_amount e total completos; nenhum valor negativo.
- order_items: 147320; quantity, unit_price e line_total completos; nenhum valor inválido/negativo.
- payments: 53546; amount completo; nenhum negativo; id sem duplicidade.
- returns: 980; total_refund_amount completo; nenhum negativo; return_number sem duplicidade.
- total_refund_amount bate com soma(quantity * unit_refund_amount) nos return_items.
- 12 devoluções acima de orders.total foram explicadas por descontos; nenhuma acima de orders.subtotal.
- customers.tax_id duplicados: 0.
- product_variants.sku duplicados: 0.
- orders.id duplicados: 0.
- payments.id duplicados: 0.
- employees.cpf duplicados: 0.
- employees: 15/15 com id, full_name, cpf, email, role e created_at.
- employees termination_date < hire_date: 0.
- payments updated_at < created_at: 0.
- returns updated_at < created_at: 0.
- rodada consolidada de nulos/valores inválidos: tudo 0.

## Regra para continuar
1. Seguir exatamente o roteiro da Indicium.
2. Não inventar etapas.
3. Não refazer trabalho concluído.
4. Agrupar consultas sempre que possível.
5. Não apagar dados já carregados no PostgreSQL.
6. Antes de nova carga, inspecionar q2_schema e q3_loading.
7. Q3 deve ser formalizada com Python 3 + biblioteca de conexão/carregamento.
8. Próxima ação: recuperar/inspecionar q2_schema; depois criar o script de q3_loading conforme o schema.
9. Só depois avançar para Q4.

## Para continuar em outra conversa
Envie este arquivo e diga:
"Continue o projeto LH Nautical a partir deste checkpoint. Siga o roteiro da Indicium e comece pela inspeção de q2_schema antes de alterar o PostgreSQL."
