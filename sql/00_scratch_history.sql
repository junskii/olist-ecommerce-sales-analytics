-- Project: E-Commerce Sales Analytics
-- Purpose: Explore the order data

USE olist_analytics;

-- Query 1: Preview sample order data
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM olist_orders
LIMIT 10;

-- Query 2: Count orders by status
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM olist_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Query 3: Count delivered orders only
SELECT
    COUNT(*) AS delivered_orders
FROM olist_orders
WHERE order_status = 'delivered';

-- Query 4: Find date range of delivered orders
SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM olist_orders
WHERE order_status = 'delivered';

-- Query 5: Combine delivered orders with their item-level sales data
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

-- Query 6: Calculate sales KPIs for delivered orders
SELECT
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Query 7: Calculate Average Order Value for delivered orders
SELECT
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Query 8: Calculate monthly sales performance for delivered orders
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM olist_orders AS o
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- Query 9: Find top product categories by GMV
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
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
ORDER BY gmv DESC
LIMIT 10;

UPDATE product_category_translation
SET product_category_name_english =
    REPLACE(product_category_name_english, CHAR(13), '');
SELECT product_category_name_english
FROM product_category_translation
LIMIT 5;

-- Query 9: Find top product categories by GMV
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
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
ORDER BY gmv DESC
LIMIT 10;

-- Query 10: Find top customer states by GMV
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM olist_orders AS o
JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY gmv DESC
LIMIT 10;

-- Query 11: Identify top repeat customers by completed orders
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM olist_orders AS o
JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
JOIN olist_order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_orders DESC, gmv DESC
LIMIT 10;

-- Query 12: Measure repeat-customer rate and GMV contribution
WITH customer_summary AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price + oi.freight_value) AS customer_gmv
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON o.customer_id = c.customer_id
    JOIN olist_order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(total_orders = 1) AS one_time_customers,
    SUM(total_orders > 1) AS repeat_customers,
    ROUND(100 * SUM(total_orders > 1) / COUNT(*), 2) AS repeat_customer_rate_pct,
    ROUND(SUM(CASE WHEN total_orders > 1 THEN customer_gmv ELSE 0 END), 2)
        AS repeat_customer_gmv
FROM customer_summary;

-- Query 13: Compare on-time and late deliveries
SELECT
    CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On time'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS average_delivery_days
FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On time'
    END;
    
-- Query 14: Compare review scores for on-time vs late deliveries.
-- Method: average multiple review records into one score per order first.

WITH delivery_summary AS (
    -- One row per delivered order: delivery status and duration
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On time'
        END AS delivery_status,
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        ) AS delivery_days
    FROM olist_orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

review_summary AS (
    -- One average review score per order
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM olist_order_reviews
    GROUP BY order_id
)

SELECT
    d.delivery_status,
    COUNT(*) AS total_orders,
    COUNT(r.order_id) AS orders_with_review,
    ROUND(AVG(d.delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(r.average_review_score), 2) AS average_review_score
FROM delivery_summary AS d
LEFT JOIN review_summary AS r
    ON d.order_id = r.order_id
GROUP BY d.delivery_status
ORDER BY average_review_score DESC;