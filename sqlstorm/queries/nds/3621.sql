
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_birth_year > 1980 
    GROUP BY c.c_customer_sk, c.c_customer_id
),
AggregateProfits AS (
    SELECT 
        SUM(total_web_profit) AS total_web_profit,
        SUM(total_catalog_profit) AS total_catalog_profit,
        SUM(total_store_profit) AS total_store_profit,
        AVG(total_web_orders) AS avg_web_orders,
        AVG(total_catalog_orders) AS avg_catalog_orders,
        AVG(total_store_orders) AS avg_store_orders
    FROM CustomerSales
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_profit,
        cs.total_catalog_profit,
        cs.total_store_profit,
        RANK() OVER (ORDER BY (cs.total_web_profit + cs.total_catalog_profit + cs.total_store_profit) DESC) AS profit_rank
    FROM CustomerSales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_web_profit,
    tc.total_catalog_profit,
    tc.total_store_profit,
    ap.total_web_profit AS overall_web_profit,
    ap.total_catalog_profit AS overall_catalog_profit,
    ap.total_store_profit AS overall_store_profit,
    ap.avg_web_orders,
    ap.avg_catalog_orders,
    ap.avg_store_orders
FROM TopCustomers tc
CROSS JOIN AggregateProfits ap
WHERE tc.profit_rank <= 10
ORDER BY profit_rank;
