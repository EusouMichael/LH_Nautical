-- ==========================================================
-- LH NAUTICAL - SCHEMA POSTGRESQL
-- Questão 2 - Desafio Lighthouse Dados e IA
-- ==========================================================

CREATE SCHEMA IF NOT EXISTS public;

-- ==========================================================
-- TABELA: addresses
-- ==========================================================
CREATE TABLE IF NOT EXISTS "addresses" (
    "id" INTEGER,
    "customer_id" INTEGER,
    "address_type" TEXT,
    "postal_code" TEXT,
    "street" TEXT,
    "number" INTEGER,
    "complement" TEXT,
    "district" TEXT,
    "city" TEXT,
    "state" TEXT,
    "country" TEXT,
    "is_primary" BOOLEAN
);

-- ==========================================================
-- TABELA: attributes
-- ==========================================================
CREATE TABLE IF NOT EXISTS "attributes" (
    "id" INTEGER,
    "name" TEXT,
    "data_type" TEXT
);

-- ==========================================================
-- TABELA: brands
-- ==========================================================
CREATE TABLE IF NOT EXISTS "brands" (
    "id" INTEGER,
    "name" TEXT,
    "country" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: categories
-- ==========================================================
CREATE TABLE IF NOT EXISTS "categories" (
    "id" INTEGER,
    "name" TEXT,
    "slug" TEXT,
    "parent_category_id" INTEGER,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: customers
-- ==========================================================
CREATE TABLE IF NOT EXISTS "customers" (
    "id" INTEGER,
    "person_type" TEXT,
    "legal_name" TEXT,
    "trade_name" TEXT,
    "tax_id" TEXT,
    "state_registration" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: employees
-- ==========================================================
CREATE TABLE IF NOT EXISTS "employees" (
    "id" INTEGER,
    "full_name" TEXT,
    "cpf" TEXT,
    "email" TEXT,
    "role" TEXT,
    "primary_location_id" INTEGER,
    "hire_date" DATE,
    "termination_date" DATE,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: fiscal_invoices
-- ==========================================================
CREATE TABLE IF NOT EXISTS "fiscal_invoices" (
    "id" INTEGER,
    "order_id" INTEGER,
    "nfe_number" TEXT,
    "nfe_access_key" TEXT,
    "series" INTEGER,
    "issued_at" TIMESTAMP,
    "status" TEXT,
    "total_amount" NUMERIC,
    "xml_storage_uri" TEXT,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: goods_receipt_items
-- ==========================================================
CREATE TABLE IF NOT EXISTS "goods_receipt_items" (
    "id" INTEGER,
    "goods_receipt_id" INTEGER,
    "purchase_order_item_id" INTEGER,
    "quantity_received" NUMERIC
);

-- ==========================================================
-- TABELA: goods_receipts
-- ==========================================================
CREATE TABLE IF NOT EXISTS "goods_receipts" (
    "id" INTEGER,
    "purchase_order_id" INTEGER,
    "received_by_employee_id" INTEGER,
    "received_at" TIMESTAMP,
    "notes" TEXT,
    "created_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: locations
-- ==========================================================
CREATE TABLE IF NOT EXISTS "locations" (
    "id" INTEGER,
    "name" TEXT,
    "location_type" TEXT,
    "postal_code" TEXT,
    "street" TEXT,
    "number" INTEGER,
    "complement" TEXT,
    "district" TEXT,
    "city" TEXT,
    "state" TEXT,
    "country" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: order_items
-- ==========================================================
CREATE TABLE IF NOT EXISTS "order_items" (
    "id" INTEGER,
    "order_id" INTEGER,
    "product_variant_id" INTEGER,
    "quantity" INTEGER,
    "unit_price" NUMERIC,
    "icms_rate" INTEGER,
    "ipi_rate" INTEGER,
    "line_total" NUMERIC
);

-- ==========================================================
-- TABELA: orders
-- ==========================================================
CREATE TABLE IF NOT EXISTS "orders" (
    "id" INTEGER,
    "order_number" TEXT,
    "channel" TEXT,
    "customer_id" INTEGER,
    "salesperson_id" INTEGER,
    "location_id" INTEGER,
    "status" TEXT,
    "subtotal" NUMERIC,
    "discount_amount" NUMERIC,
    "total" NUMERIC,
    "placed_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: payments
-- ==========================================================
CREATE TABLE IF NOT EXISTS "payments" (
    "id" INTEGER,
    "order_id" INTEGER,
    "method" TEXT,
    "installments" INTEGER,
    "amount" NUMERIC,
    "status" TEXT,
    "paid_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: product_suppliers
-- ==========================================================
CREATE TABLE IF NOT EXISTS "product_suppliers" (
    "product_variant_id" INTEGER,
    "supplier_id" INTEGER,
    "supplier_sku" TEXT,
    "last_quoted_cost" NUMERIC,
    "lead_time_days" INTEGER,
    "is_preferred" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: product_variants
-- ==========================================================
CREATE TABLE IF NOT EXISTS "product_variants" (
    "id" INTEGER,
    "product_id" INTEGER,
    "sku" TEXT,
    "barcode_ean" TEXT,
    "sale_price" NUMERIC,
    "cost_price" NUMERIC,
    "weight_kg" NUMERIC,
    "icms_rate" INTEGER,
    "ipi_rate" INTEGER,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: products
-- ==========================================================
CREATE TABLE IF NOT EXISTS "products" (
    "id" INTEGER,
    "name" TEXT,
    "description" TEXT,
    "brand_id" INTEGER,
    "category_id" INTEGER,
    "ncm_code" TEXT,
    "unit_of_measure" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: purchase_order_items
-- ==========================================================
CREATE TABLE IF NOT EXISTS "purchase_order_items" (
    "id" INTEGER,
    "purchase_order_id" INTEGER,
    "product_variant_id" INTEGER,
    "quantity_ordered" INTEGER,
    "unit_cost" NUMERIC,
    "line_total" NUMERIC
);

-- ==========================================================
-- TABELA: purchase_orders
-- ==========================================================
CREATE TABLE IF NOT EXISTS "purchase_orders" (
    "id" INTEGER,
    "po_number" TEXT,
    "supplier_id" INTEGER,
    "buyer_id" INTEGER,
    "destination_location_id" INTEGER,
    "status" TEXT,
    "currency" TEXT,
    "subtotal" NUMERIC,
    "total" NUMERIC,
    "placed_at" TIMESTAMP,
    "expected_delivery_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: return_items
-- ==========================================================
CREATE TABLE IF NOT EXISTS "return_items" (
    "id" INTEGER,
    "return_id" INTEGER,
    "order_item_id" INTEGER,
    "quantity" INTEGER,
    "action" TEXT,
    "exchange_variant_id" INTEGER,
    "unit_refund_amount" NUMERIC
);

-- ==========================================================
-- TABELA: returns
-- ==========================================================
CREATE TABLE IF NOT EXISTS "returns" (
    "id" INTEGER,
    "return_number" TEXT,
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "received_at_location_id" INTEGER,
    "status" TEXT,
    "reason" TEXT,
    "total_refund_amount" NUMERIC,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: stock_levels
-- ==========================================================
CREATE TABLE IF NOT EXISTS "stock_levels" (
    "product_variant_id" INTEGER,
    "location_id" INTEGER,
    "quantity_on_hand" NUMERIC,
    "reorder_point" INTEGER,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: stock_movements
-- ==========================================================
CREATE TABLE IF NOT EXISTS "stock_movements" (
    "id" INTEGER,
    "product_variant_id" INTEGER,
    "location_id" INTEGER,
    "movement_type" TEXT,
    "quantity" NUMERIC,
    "reference_table" TEXT,
    "reference_id" INTEGER,
    "employee_id" INTEGER,
    "notes" TEXT,
    "occurred_at" TIMESTAMP,
    "created_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: suppliers
-- ==========================================================
CREATE TABLE IF NOT EXISTS "suppliers" (
    "id" INTEGER,
    "legal_name" TEXT,
    "trade_name" TEXT,
    "country" TEXT,
    "tax_id" TEXT,
    "tax_id_type" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "contact_name" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

-- ==========================================================
-- TABELA: variant_attribute_values
-- ==========================================================
CREATE TABLE IF NOT EXISTS "variant_attribute_values" (
    "product_variant_id" INTEGER,
    "attribute_id" INTEGER,
    "value" TEXT
);
