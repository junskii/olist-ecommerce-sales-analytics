/*
Proyek: E-Commerce Sales Analytics

Tujuan file:
Melakukan eksplorasi dasar terhadap data order sebelum masuk ke
analisis bisnis yang lebih mendalam.

Cakupan:
- Menggunakan tabel order dan detail item order.
- Mengenali struktur data, status order, periode data, serta KPI dasar.
- Query analisis bisnis utama disimpan terpisah di 04_business_analysis.sql.
*/

USE olist_analytics;

-- ============================================================
-- Eksplorasi 1: Melihat contoh struktur data order.
-- ============================================================

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM olist_orders
LIMIT 10;

-- ============================================================
-- Eksplorasi 2: Melihat jumlah order pada setiap status.
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS jumlah_order
FROM olist_orders
GROUP BY order_status
ORDER BY jumlah_order DESC;

-- ============================================================
-- Eksplorasi 3: Menghitung jumlah order yang sudah selesai
-- dikirim kepada customer.
-- ============================================================

SELECT
    COUNT(*) AS jumlah_order_delivered
FROM olist_orders
WHERE order_status = 'delivered';

-- ============================================================
-- Eksplorasi 4: Menentukan rentang waktu completed order.
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS tanggal_order_pertama,
    MAX(order_purchase_timestamp) AS tanggal_order_terakhir
FROM olist_orders
WHERE order_status = 'delivered';

-- ============================================================
-- Eksplorasi 5: Melihat hasil penggabungan order dengan detail
-- itemnya. Satu order dapat memiliki lebih dari satu item.
-- ============================================================

SELECT
    o.order_id,
    o.order_purchase_timestamp,
    oi.order_item_id,
    oi.price,
    oi.freight_value
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
LIMIT 10;

-- ============================================================
-- Eksplorasi 6: Menghitung KPI sales utama untuk order delivered.
--
-- Product revenue: total harga produk.
-- Freight revenue: total biaya pengiriman.
-- GMV: total nilai transaksi, yaitu harga produk + ongkir.
-- ============================================================

SELECT
    COUNT(DISTINCT o.order_id) AS jumlah_order_delivered,
    COUNT(*) AS jumlah_item_terjual,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- ============================================================
-- Eksplorasi 7: Menghitung Average Order Value (AOV).
--
-- Rumus:
-- AOV = GMV / jumlah order unik
-- ============================================================

SELECT
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS rata_rata_nilai_order
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';