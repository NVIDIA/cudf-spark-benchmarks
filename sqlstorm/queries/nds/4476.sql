
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    CASE 
        WHEN s.sales_rank <= 10 THEN 'Top 10'
        WHEN s.sales_rank BETWEEN 11 AND 50 THEN 'Top 50'
        ELSE 'Others'
    END AS sales_category,
    s.total_web_sales + s.total_catalog_sales + s.total_store_sales AS overall_sales
FROM 
    SalesRanked s
WHERE 
    (s.total_web_sales > 5000 OR s.total_catalog_sales > 5000 OR s.total_store_sales > 5000)
    AND s.c_customer_sk IS NOT NULL
ORDER BY 
    overall_sales DESC
LIMIT 100;
