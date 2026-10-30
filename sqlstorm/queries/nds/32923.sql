WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2454560 AND 2454580 
    GROUP BY ws_item_sk
),
customer_activity AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS average_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        ca.c_customer_sk,
        ca.total_orders,
        ca.average_spent,
        ROW_NUMBER() OVER (ORDER BY ca.average_spent DESC) AS ranking
    FROM customer_activity ca
    WHERE ca.total_orders > 0
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CASE 
        WHEN ca.total_orders IS NULL THEN 'No Orders'
        ELSE CAST(ca.total_orders AS STRING)
    END AS order_count,
    COALESCE(ca.average_spent, 0) AS avg_spent,
    ss.total_quantity,
    ss.total_net_profit
FROM customer c
LEFT JOIN top_customers ca ON c.c_customer_sk = ca.c_customer_sk
LEFT JOIN sales_summary ss ON ss.ws_item_sk IN (
    SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_ship_date_sk IS NOT NULL
)
WHERE ca.ranking <= 10 
OR ss.total_net_profit > 1000 
ORDER BY ca.average_spent DESC, ss.total_net_profit DESC;