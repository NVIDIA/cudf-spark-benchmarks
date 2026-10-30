
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(SUM(ss.ss_sales_price), 0) AS store_sales,
        COALESCE(SUM(ws.ws_sales_price), 0) AS web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesRank AS (
    SELECT 
        c_customer_sk, 
        store_sales + web_sales AS total_sales,
        RANK() OVER (ORDER BY store_sales + web_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    COUNT(*) AS active_customers,
    MAX(total_sales) AS max_sales,
    AVG(CASE WHEN sales_rank <= 10 THEN total_sales ELSE NULL END) AS avg_top_10_sales,
    SUM(CASE WHEN sales_rank BETWEEN 11 AND 20 THEN total_sales ELSE 0 END) AS sum_rank_11_to_20,
    (SELECT SUM(total_sales) FROM SalesRank WHERE sales_rank % 2 = 0) AS even_ranked_customers_sales,
    STRING_AGG(DISTINCT CASE 
        WHEN total_sales IS NULL THEN 'NULL Sales'
        WHEN total_sales = 0 THEN 'No Sales'
        ELSE CAST(total_sales AS STRING)
    END, ', ') AS sales_description,
    COUNT(DISTINCT CASE 
        WHEN total_sales IS NULL THEN c_customer_sk 
        ELSE NULL 
    END) AS null_sales_customers
FROM 
    SalesRank
WHERE 
    total_sales > (
        SELECT AVG(total_sales) 
        FROM SalesRank
    )
GROUP BY 
    (SELECT 
        NULLIF(COUNT(DISTINCT c_customer_sk), 0)
    FROM CustomerSales);
