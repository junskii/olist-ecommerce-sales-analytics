/*
Proyek: E-Commerce Sales Analytics

Tujuan:
Menganalisis performa penjualan e-commerce, kategori produk, wilayah customer,
perilaku repeat customer, serta dampak performa pengiriman terhadap kepuasan customer.

Cakupan analisis:
- Hanya menggunakan order dengan status 'delivered'.
- GMV dihitung dari total harga produk dan freight/ongkir.
- Periode data: September 2016 sampai Agustus 2018.

File ini berisi query untuk menjawab pertanyaan bisnis utama.
*/

-- ============================================================
-- Pertanyaan Bisnis 1: Bagaimana tren penjualan dari bulan
-- ke bulan berdasarkan jumlah order, GMV, dan rata-rata nilai order?
-- ============================================================

-- Metode:
-- 1. Menggabungkan tabel order dengan detail item order.
-- 2. Memakai hanya order yang sudah delivered.
-- 3. Mengelompokkan transaksi berdasarkan bulan pembelian.
-- 4. Menghitung jumlah order unik, GMV, dan average order value.
USE olist_analytics;
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS bulan_order,
    COUNT(DISTINCT o.order_id) AS jumlah_order,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS rata_rata_nilai_order
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY bulan_order;

-- ============================================================
-- Pertanyaan Bisnis 2: Kategori produk mana yang memberikan
-- kontribusi GMV terbesar?
-- ============================================================

-- Metode:
-- 1. Menghubungkan item order dengan informasi produk.
-- 2. Menggunakan tabel terjemahan agar nama kategori lebih mudah dibaca.
-- 3. Tetap menampilkan produk tanpa terjemahan atau tanpa kategori.
-- 4. Mengurutkan hasil berdasarkan GMV dari terbesar ke terkecil.

SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS kategori_produk,
    COUNT(DISTINCT oi.order_id) AS jumlah_order,
    COUNT(*) AS jumlah_item_terjual,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
JOIN olist_products AS p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY gmv DESC;

-- ============================================================
-- Pertanyaan Bisnis 3: Wilayah customer mana yang memberikan
-- kontribusi GMV dan jumlah order terbesar?
-- ============================================================

-- Metode:
-- 1. Menghubungkan order dengan lokasi customer.
-- 2. Menggabungkan order dengan detail item untuk menghitung GMV.
-- 3. Mengelompokkan hasil berdasarkan state/provinsi customer.
-- 4. Mengurutkan state berdasarkan GMV dari terbesar ke terkecil.

SELECT
    c.customer_state AS state_customer,
    COUNT(DISTINCT o.order_id) AS jumlah_order,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM olist_orders AS o
JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY gmv DESC;

-- ============================================================
-- Pertanyaan Bisnis 4: Seberapa besar proporsi repeat customer
-- dan kontribusi GMV mereka?
-- ============================================================

-- Metode:
-- 1. Menggunakan customer_unique_id untuk mengenali customer yang sama
--    pada beberapa order.
-- 2. Menghitung jumlah completed order dan GMV untuk setiap customer.
-- 3. Memisahkan customer satu kali beli dan customer yang membeli lebih dari sekali.

WITH ringkasan_customer AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS jumlah_order,
        SUM(oi.price + oi.freight_value) AS gmv_customer
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON o.customer_id = c.customer_id
    JOIN olist_order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customer,
    SUM(jumlah_order = 1) AS customer_satu_kali_beli,
    SUM(jumlah_order > 1) AS repeat_customer,
    ROUND(
        100 * SUM(jumlah_order > 1) / COUNT(*),
        2
    ) AS repeat_customer_rate_persen,
    ROUND(
        SUM(
            CASE
                WHEN jumlah_order > 1 THEN gmv_customer
                ELSE 0
            END
        ),
        2
    ) AS gmv_repeat_customer
FROM ringkasan_customer;

-- ============================================================
-- Pertanyaan Bisnis 5: Apakah order yang terlambat memiliki
-- rata-rata review score lebih rendah?
-- ============================================================

-- Metode:
-- 1. Menentukan status pengiriman: Late atau On time.
-- 2. Menghitung rata-rata review terlebih dahulu untuk setiap order.
--    Hal ini membuat setiap order memiliki bobot yang sama, meskipun
--    ada order yang memiliki lebih dari satu baris review.
-- 3. Membandingkan rata-rata review score kedua kelompok pengiriman.

WITH ringkasan_pengiriman AS (
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On time'
        END AS status_pengiriman,
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        ) AS durasi_pengiriman_hari
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

ringkasan_review AS (
    SELECT
        order_id,
        AVG(review_score) AS rata_rata_review_score
    FROM olist_order_reviews
    GROUP BY order_id
)

SELECT
    p.status_pengiriman,
    COUNT(*) AS total_order,
    COUNT(r.order_id) AS order_dengan_review,
    ROUND(AVG(p.durasi_pengiriman_hari), 2) AS rata_rata_durasi_pengiriman_hari,
    ROUND(AVG(r.rata_rata_review_score), 2) AS rata_rata_review_score
FROM ringkasan_pengiriman AS p
LEFT JOIN ringkasan_review AS r
    ON p.order_id = r.order_id
GROUP BY p.status_pengiriman
ORDER BY rata_rata_review_score DESC;