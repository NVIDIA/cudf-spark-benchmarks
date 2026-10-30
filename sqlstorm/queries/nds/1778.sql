
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_ext_sales_price
    FROM ranked_sales rs
    JOIN item ON rs.ws_item_sk = item.i_item_sk
    WHERE rs.rn = 1
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(ts.ws_order_number) AS total_orders,
    SUM(ts.ws_ext_sales_price) AS total_revenue,
    AVG(ts.ws_sales_price) AS avg_sales_price
FROM top_sales ts
JOIN customer c ON ts.ws_order_number = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(ts.ws_ext_sales_price) > 1000
ORDER BY total_revenue DESC
LIMIT 10;
