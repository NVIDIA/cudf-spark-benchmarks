
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_orders,
        cs.total_web_profit,
        COALESCE(ss.total_store_profit, 0) AS total_store_profit
    FROM CustomerSales cs
    LEFT JOIN StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        cs.total_web_orders,
        cs.total_web_profit,
        cs.total_store_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_web_profit DESC) AS web_profit_rank,
        DENSE_RANK() OVER (ORDER BY cs.total_store_profit DESC) AS store_profit_rank
    FROM SalesSummary cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.total_web_orders,
    r.total_web_profit,
    r.total_store_profit,
    r.web_profit_rank,
    r.store_profit_rank,
    CASE 
        WHEN r.web_profit_rank < r.store_profit_rank THEN 'Web'
        ELSE 'Store'
    END AS preferred_channel
FROM RankedSales r
WHERE r.total_web_profit > 0 OR r.total_store_profit > 0
ORDER BY r.total_web_profit DESC, r.total_store_profit DESC
LIMIT 100;
