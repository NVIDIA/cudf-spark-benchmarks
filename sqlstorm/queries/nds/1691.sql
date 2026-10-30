
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_store_sales + total_web_sales DESC) AS sales_rank
    FROM CustomerSales
),
HighValueCustomers AS (
    SELECT 
        c.*,
        CASE 
            WHEN total_store_sales + total_web_sales > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_value
    FROM SalesRanked AS c
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_store_sales,
    h.total_web_sales,
    h.total_returns,
    h.sales_rank,
    h.customer_value
FROM HighValueCustomers AS h
WHERE h.customer_value = 'High Value'
ORDER BY h.sales_rank
LIMIT 100;
