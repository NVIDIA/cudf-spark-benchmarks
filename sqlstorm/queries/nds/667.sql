
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id
),
SalesRanked AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.store_transactions,
        cs.web_transactions,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
)
SELECT 
    sr.c_customer_id,
    sr.total_sales,
    sr.store_transactions,
    sr.web_transactions,
    CASE 
        WHEN sr.sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN sr.sales_rank BETWEEN 11 AND 20 THEN 'Next 10 Customers'
        ELSE 'Others'
    END AS customer_category
FROM SalesRanked sr
WHERE sr.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
ORDER BY sr.total_sales DESC;
