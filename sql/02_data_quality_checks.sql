/*
Proyek: E-Commerce Sales Analytics

Tujuan file:
Memvalidasi hasil impor data sebelum analisis dilakukan.

Pengecekan meliputi:
- Jumlah baris pada setiap tabel.
- Missing value pada kolom penting.
- Konsistensi relasi antar tabel.
- Kategori produk yang belum memiliki terjemahan.
*/

-- ============================================================
-- 1. Memeriksa jumlah baris pada setiap tabel setelah impor.
-- ============================================================
USE olist_analytics;

SELECT 'olist_customers' AS nama_tabel, COUNT(*) AS jumlah_baris
FROM olist_customers

UNION ALL

SELECT 'olist_orders', COUNT(*)
FROM olist_orders

UNION ALL

SELECT 'olist_order_items', COUNT(*)
FROM olist_order_items

UNION ALL

SELECT 'olist_order_payments', COUNT(*)
FROM olist_order_payments

UNION ALL

SELECT 'olist_order_reviews', COUNT(*)
FROM olist_order_reviews

UNION ALL

SELECT 'olist_products', COUNT(*)
FROM olist_products

UNION ALL

SELECT 'olist_sellers', COUNT(*)
FROM olist_sellers

UNION ALL

SELECT 'olist_geolocation', COUNT(*)
FROM olist_geolocation

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM product_category_translation;

-- ============================================================
-- 2. Memeriksa missing value pada kolom penting.
-- ============================================================

SELECT
    'orders: tanggal approval kosong' AS pemeriksaan,
    COUNT(*) AS jumlah_missing
FROM olist_orders
WHERE order_approved_at IS NULL

UNION ALL

SELECT
    'orders: tanggal diserahkan ke kurir kosong',
    COUNT(*)
FROM olist_orders
WHERE order_delivered_carrier_date IS NULL

UNION ALL

SELECT
    'orders: tanggal diterima customer kosong',
    COUNT(*)
FROM olist_orders
WHERE order_delivered_customer_date IS NULL

UNION ALL

SELECT
    'products: kategori kosong',
    COUNT(*)
FROM olist_products
WHERE product_category_name IS NULL

UNION ALL

SELECT
    'products: berat produk kosong',
    COUNT(*)
FROM olist_products
WHERE product_weight_g IS NULL

UNION ALL

SELECT
    'reviews: judul komentar kosong',
    COUNT(*)
FROM olist_order_reviews
WHERE review_comment_title IS NULL

UNION ALL

SELECT
    'reviews: isi komentar kosong',
    COUNT(*)
FROM olist_order_reviews
WHERE review_comment_message IS NULL;

-- ============================================================
-- 3. Memeriksa apakah setiap data transaksi memiliki pasangan
-- pada tabel yang berelasi.
--
-- Semua hasil pada bagian ini seharusnya bernilai 0.
-- ============================================================

SELECT
    'order tanpa customer' AS pemeriksaan,
    COUNT(*) AS jumlah_data
FROM olist_orders AS o
LEFT JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'item tanpa order',
    COUNT(*)
FROM olist_order_items AS oi
LEFT JOIN olist_orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'item tanpa produk',
    COUNT(*)
FROM olist_order_items AS oi
LEFT JOIN olist_products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'item tanpa seller',
    COUNT(*)
FROM olist_order_items AS oi
LEFT JOIN olist_sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT
    'pembayaran tanpa order',
    COUNT(*)
FROM olist_order_payments AS op
LEFT JOIN olist_orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'review tanpa order',
    COUNT(*)
FROM olist_order_reviews AS r
LEFT JOIN olist_orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;