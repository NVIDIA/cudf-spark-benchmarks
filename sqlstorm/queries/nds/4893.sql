
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
ranked_sales AS (
    SELECT 
        c_customer_id,
        total_net_profit,
        online_orders,
        catalog_orders,
        store_orders,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM customer_sales
),
top_customers AS (
    SELECT 
        *,
        CASE 
            WHEN profit_rank <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS customer_category
    FROM ranked_sales
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.online_orders,
    tc.catalog_orders,
    tc.store_orders,
    tc.customer_category,
    CASE 
        WHEN tc.online_orders > 0 AND tc.catalog_orders > 0 AND tc.store_orders > 0 THEN 'Multichannel'
        WHEN tc.online_orders > 0 THEN 'Online Only'
        WHEN tc.catalog_orders > 0 THEN 'Catalog Only'
        WHEN tc.store_orders > 0 THEN 'In-store Only'
        ELSE 'No Orders'
    END AS sales_channel
FROM top_customers tc
WHERE tc.total_net_profit > (SELECT AVG(total_net_profit) FROM ranked_sales)
ORDER BY tc.total_net_profit DESC
LIMIT 50;

