
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2458180 AND 2458183
),
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_sales_price, 0) * COALESCE(ws.ws_quantity, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        i.i_item_sk
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_country IS NOT NULL
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT 
    isum.i_product_name,
    isum.total_quantity,
    isum.total_sales,
    tc.c_customer_id,
    tc.total_orders,
    tc.total_profit
FROM item_summary isum
JOIN top_customers tc ON isum.total_quantity > 50
LEFT JOIN ranked_sales rs ON isum.i_item_sk = rs.ws_item_sk
WHERE rs.sales_rank = 1 OR rs.ws_order_number IS NULL
ORDER BY isum.total_sales DESC, tc.total_profit ASC
LIMIT 100;
