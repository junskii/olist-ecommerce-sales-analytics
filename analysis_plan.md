# Analysis Plan

## Business Objective
Evaluate e-commerce sales performance and identify the product categories, customer locations, and operational factors that most influence business performance.

## Analysis Scope
Primary analysis uses orders with `order_status = 'delivered'`.

## KPI Definitions
- Total Orders: COUNT(DISTINCT order_id)
- Total Product Revenue: SUM(price)
- Total Freight Cost: SUM(freight_value)
- GMV: SUM(price + freight_value)
- Average Order Value: GMV / Total Orders
- Average Delivery Time: delivered_customer_date - purchase_timestamp
- Late Delivery Rate: delivered_customer_date > estimated_delivery_date
- Average Review Score: AVG(review_score)

## Business Questions
1. How did monthly orders and GMV change over time?
2. Which product categories contribute the most GMV and orders?
3. Which states generate the highest GMV and order volume?
4. Which customers are repeat buyers, and how much do they contribute?
5. How do delivery time and late deliveries relate to review scores?