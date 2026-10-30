
WITH  sales_cte AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
high_spenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM customer_summary cs
    WHERE cs.total_spent IS NOT NULL
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
    HAVING COUNT(DISTINCT ws.ws_order_number) > 10
)
SELECT 
    h.c_customer_sk,
    h.total_orders,
    h.total_spent,
    p.i_item_sk,
    p.order_count,
    CASE 
        WHEN h.spend_rank <= 5 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS customer_status
FROM high_spenders h
LEFT JOIN popular_items p ON h.c_customer_sk = p.i_item_sk
WHERE p.i_item_sk IS NOT NULL
    AND (SELECT SUM(cs.total_spent) FROM high_spenders cs WHERE cs.c_customer_sk = h.c_customer_sk) > 1000
ORDER BY h.total_spent DESC, p.order_count DESC
LIMIT 100;
