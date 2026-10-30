
WITH  sales_data AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_within_item
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), cumulative_sales AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           total_sales,
           total_orders,
           SUM(total_sales) OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS cumulative_sales_amount
    FROM sales_data
),
item_details AS (
    SELECT i_item_sk,
           i_product_name,
           i_current_price,
           COALESCE(SUM(CASE WHEN ws_ship_date_sk IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_shipped,
           COALESCE(AVG(ws_sales_price / NULLIF(ws_list_price, 0)), 0) AS avg_discount
    FROM item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY i_item_sk, i_product_name, i_current_price
)
SELECT ca_state,
       COUNT(DISTINCT c_customer_sk) AS unique_customers,
       SUM(CASE WHEN ws_ext_sales_price > 0 THEN ws_ext_sales_price ELSE 0 END) AS total_revenue,
       AVG(CASE WHEN total_orders > 0 THEN total_sales / total_orders ELSE NULL END) AS avg_sales_per_order,
       STRING_AGG(i_product_name, ', ') AS top_products
FROM customer_address 
LEFT JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
LEFT JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
LEFT JOIN cumulative_sales ON web_sales.ws_item_sk = cumulative_sales.ws_item_sk
LEFT JOIN item_details ON cumulative_sales.ws_item_sk = item_details.i_item_sk
WHERE ca_state IS NOT NULL
GROUP BY ca_state
ORDER BY total_revenue DESC
LIMIT 10;
