
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_net_profit AS store_net_profit,
        COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY COALESCE(ws.ws_net_profit, 0) DESC) AS profit_rank
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_order_number = ss.ss_ticket_number
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_profit,
        sd.profit_rank
    FROM SalesData sd
    WHERE sd.profit_rank = 1
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) > (SELECT AVG(total_spent) FROM (SELECT SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent FROM customer c LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk GROUP BY c.c_customer_sk) AS customer_spending)
)
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS high_value_customer_count,
    SUM(ts.total_profit) AS total_high_value_profit
FROM TopSales ts
JOIN HighValueCustomers hvc ON ts.ws_item_sk IN (SELECT DISTINCT cs.cs_item_sk FROM catalog_sales cs) 
JOIN customer c ON c.c_customer_sk = hvc.c_customer_sk
WHERE hvc.total_spent IS NOT NULL
AND ts.total_profit IS NOT NULL
AND (ts.total_profit > 100 OR ts.total_profit IS NOT NULL)
GROUP BY ts.profit_rank
HAVING COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY total_high_value_profit DESC;
