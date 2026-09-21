/*
Proyek: E-Commerce Sales Analytics

Tujuan file:
Menyiapkan database MySQL, membuat struktur tabel, dan mengimpor
dataset Olist dari file CSV.

Catatan:
- File CSV disimpan di folder utama project.
- Tabel dibuat tanpa foreign key agar proses impor lebih sederhana.
- File review memakai versi clean agar karakter khusus dalam komentar
  tidak mengganggu proses impor.
*/

-- ============================================================
-- 1. Membuat dan memilih database.
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist_analytics
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE olist_analytics;

-- ============================================================
-- 2. Membuat tabel customer dan order.
-- ============================================================

CREATE TABLE IF NOT EXISTS olist_customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix CHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS olist_orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME,
    INDEX idx_orders_customer (customer_id)
);

-- ============================================================
-- 3. Membuat tabel detail item order, pembayaran, dan review.
-- ============================================================

CREATE TABLE IF NOT EXISTS olist_order_items (
    order_id CHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_product (product_id),
    INDEX idx_items_seller (seller_id)
);

CREATE TABLE IF NOT EXISTS olist_order_payments (
    order_id CHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS olist_order_reviews (
    review_id CHAR(32),
    order_id CHAR(32) NOT NULL,
    review_score TINYINT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    INDEX idx_reviews_order (order_id)
);

-- ============================================================
-- 4. Membuat tabel produk, seller, dan terjemahan kategori.
-- ============================================================

CREATE TABLE IF NOT EXISTS olist_products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS olist_sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix CHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- ============================================================
-- 5. Membuat tabel geolocation.
-- Presisi koordinat diperbesar agar latitude dan longitude
-- tidak terpotong saat impor.
-- ============================================================

CREATE TABLE IF NOT EXISTS olist_geolocation (
    geolocation_zip_code_prefix CHAR(5),
    geolocation_lat DECIMAL(23,20),
    geolocation_lng DECIMAL(23,20),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2),
    INDEX idx_geo_zip (geolocation_zip_code_prefix)
);

-- ============================================================
-- 6. Mengimpor tabel master: customer, produk, seller, dan
-- terjemahan nama kategori.
-- ============================================================

-- Impor data customer.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_customers_dataset.csv'
INTO TABLE olist_customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
);

-- Impor data produk.
-- NULLIF() mengubah nilai kosong pada CSV menjadi NULL.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_products_dataset.csv'
INTO TABLE olist_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    product_id,
    @product_category_name,
    @product_name_lenght,
    @product_description_lenght,
    @product_photos_qty,
    @product_weight_g,
    @product_length_cm,
    @product_height_cm,
    @product_width_cm
)
SET
    product_category_name = NULLIF(@product_category_name, ''),
    product_name_lenght = NULLIF(@product_name_lenght, ''),
    product_description_lenght = NULLIF(@product_description_lenght, ''),
    product_photos_qty = NULLIF(@product_photos_qty, ''),
    product_weight_g = NULLIF(@product_weight_g, ''),
    product_length_cm = NULLIF(@product_length_cm, ''),
    product_height_cm = NULLIF(@product_height_cm, ''),
    product_width_cm = NULLIF(@product_width_cm, '');

-- Impor data seller.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_sellers_dataset.csv'
INTO TABLE olist_sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
);

-- Impor terjemahan nama kategori.
-- File ini memakai line ending CRLF, sehingga menggunakan '\r\n'.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/product_category_name_translation.csv'
INTO TABLE product_category_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    product_category_name,
    product_category_name_english
);

-- ============================================================
-- 7. Mengimpor data transaksi: order, detail item, pembayaran,
-- review, dan geolocation.
-- ============================================================

-- Impor data order.
-- Kolom tanggal yang kosong diubah menjadi NULL.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_orders_dataset.csv'
INTO TABLE olist_orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    order_id,
    customer_id,
    order_status,
    @order_purchase_timestamp,
    @order_approved_at,
    @order_delivered_carrier_date,
    @order_delivered_customer_date,
    @order_estimated_delivery_date
)
SET
    order_purchase_timestamp = NULLIF(@order_purchase_timestamp, ''),
    order_approved_at = NULLIF(@order_approved_at, ''),
    order_delivered_carrier_date = NULLIF(@order_delivered_carrier_date, ''),
    order_delivered_customer_date = NULLIF(@order_delivered_customer_date, ''),
    order_estimated_delivery_date = NULLIF(@order_estimated_delivery_date, '');

-- Impor detail item pada setiap order.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_order_items_dataset.csv'
INTO TABLE olist_order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
);

-- Impor data pembayaran.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
);

-- Impor data review.
-- Menggunakan file clean karena file raw memiliki line break dan
-- karakter khusus pada sebagian kecil isi komentar.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_order_reviews_clean.csv'
INTO TABLE olist_order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    review_id,
    order_id,
    review_score,
    @review_comment_title,
    @review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SET
    review_comment_title = NULLIF(@review_comment_title, ''),
    review_comment_message = NULLIF(@review_comment_message, '');

-- Impor data koordinat lokasi.
LOAD DATA LOCAL INFILE
'/path/to/ECommerce-Sales-Analytics/olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
);