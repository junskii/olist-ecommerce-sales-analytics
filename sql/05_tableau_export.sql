/*
Tujuan:
Menyiapkan data level order untuk dashboard Tableau.
Satu baris mewakili satu order berstatus delivered.
*/
USE olist_analytics;

WITH ringkasan_item AS (
    SELECT
        order_id,
        COUNT(*) AS jumlah_item,
        SUM(price) AS product_revenue,
        SUM(freight_value) AS freight_revenue,
        SUM(price + freight_value) AS gmv
    FROM olist_order_items
    GROUP BY order_id
),

ringkasan_review AS (
    SELECT
        order_id,
        AVG(review_score) AS rata_rata_review_score
    FROM olist_order_reviews
    GROUP BY order_id
)

SELECT
    o.order_id,
    c.customer_unique_id,
    DATE(o.order_purchase_timestamp) AS tanggal_order,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS bulan_order,
    c.customer_state,
    c.customer_city,
    ri.jumlah_item,
    ROUND(ri.product_revenue, 2) AS product_revenue,
    ROUND(ri.freight_revenue, 2) AS freight_revenue,
    ROUND(ri.gmv, 2) AS gmv,
    DATEDIFF(
        o.order_delivered_customer_date,
        o.order_purchase_timestamp
    ) AS durasi_pengiriman_hari,
    CASE
    WHEN o.order_delivered_customer_date IS NULL
      OR o.order_estimated_delivery_date IS NULL
        THEN 'Unknown'
    WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 'Late'
    ELSE 'On time'
END AS status_pengiriman,
    ROUND(rr.rata_rata_review_score, 2) AS rata_rata_review_score
FROM olist_orders AS o
JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
JOIN ringkasan_item AS ri
    ON o.order_id = ri.order_id
LEFT JOIN ringkasan_review AS rr
    ON o.order_id = rr.order_id
WHERE o.order_status = 'delivered';

/*
Tujuan:
Menyiapkan data level item order untuk analisis kategori produk.
Satu baris mewakili satu item yang terjual dalam completed order.
*/

SELECT
    o.order_id,
    DATE(o.order_purchase_timestamp) AS tanggal_order,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS bulan_order,
    c.customer_state,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS kategori_produk,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2) AS gmv_item
FROM olist_orders AS o
JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
JOIN olist_products AS p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered';