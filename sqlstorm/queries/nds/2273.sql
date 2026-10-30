
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT CASE WHEN ss.ss_net_paid IS NOT NULL THEN ss.ss_ticket_number END) AS store_trans_count,
        COUNT(DISTINCT CASE WHEN ws.ws_net_paid IS NOT NULL THEN ws.ws_order_number END) AS web_trans_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        COUNT(c_customer_sk) AS num_customers
    FROM CustomerSales
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales > (SELECT avg_sales FROM AvgSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison,
    cs.store_trans_count,
    cs.web_trans_count
FROM CustomerSales cs
WHERE cs.total_sales > 100
ORDER BY cs.total_sales DESC
LIMIT 10;
