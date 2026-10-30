
WITH CustomerOrderStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
)
SELECT 
    cos.c_customer_sk,
    cos.c_first_name,
    cos.c_last_name,
    COALESCE(cos.total_orders, 0) AS total_orders,
    COALESCE(cos.total_profit, 0) AS total_profit,
    COALESCE(cos.avg_order_value, 0) AS avg_order_value,
    CASE 
        WHEN cos.total_orders = 0 THEN 'No Orders'
        WHEN cos.profit_rank <= 10 THEN 'High Profit'
        ELSE 'Regular Customer'
    END AS customer_category,
    (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_country = 'USA') AS total_addresses_in_usa
FROM CustomerOrderStats cos
JOIN (SELECT DISTINCT cd_demo_sk, cd_gender FROM customer_demographics) cd ON cos.c_customer_sk = cd.cd_demo_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk IN (
    SELECT DISTINCT ws.ws_warehouse_sk 
    FROM web_sales ws 
    WHERE ws.ws_item_sk IN (
        SELECT i.i_item_sk 
        FROM item i 
        WHERE i.i_product_name LIKE '%Eco%'
    )
)
WHERE cos.total_profit IS NOT NULL
ORDER BY cos.total_profit DESC
LIMIT 100;
