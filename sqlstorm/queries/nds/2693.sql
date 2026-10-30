
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT CASE 
                          WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number 
                          ELSE NULL 
                       END) AS store_sales_count,
        COUNT(DISTINCT CASE 
                          WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number 
                          ELSE NULL 
                       END) AS web_sales_count,
        COUNT(DISTINCT CASE 
                          WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number 
                          ELSE NULL 
                       END) AS catalog_sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.store_sales_count,
        cs.web_sales_count,
        cs.catalog_sales_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_spent,
    COALESCE(sr.store_sales_count, 0) AS store_sales_count,
    COALESCE(sr.web_sales_count, 0) AS web_sales_count,
    COALESCE(sr.catalog_sales_count, 0) AS catalog_sales_count,
    sr.sales_rank,
    CASE 
        WHEN sr.sales_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM SalesRanked sr
WHERE sr.total_spent > 1000
ORDER BY sr.sales_rank;
