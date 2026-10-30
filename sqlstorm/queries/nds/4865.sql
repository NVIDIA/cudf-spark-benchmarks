
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS online_orders,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_orders,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
GroupedSales AS (
    SELECT 
        total_net_profit,
        COUNT(*) AS customer_count
    FROM CustomerSales
    WHERE total_net_profit > (
        SELECT AVG(total_net_profit) FROM CustomerSales
    )
    GROUP BY total_net_profit
)
SELECT 
    total_net_profit,
    customer_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (PARTITION BY total_net_profit ORDER BY customer_count DESC) AS dense_rank
FROM GroupedSales
WHERE customer_count > 1
ORDER BY profit_rank
LIMIT 10;
