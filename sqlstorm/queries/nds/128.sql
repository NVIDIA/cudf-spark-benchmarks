
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesAggregates AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(total_web_sales, 0) AS total_web_sales,
        COALESCE(total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(total_store_sales, 0) AS total_store_sales,
        (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales c
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_web_sales,
        c.total_catalog_sales,
        c.total_store_sales,
        c.total_sales,
        ROW_NUMBER() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        SalesAggregates c
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.total_sales,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS sales_category
FROM 
    RankedSales r
WHERE 
    r.total_sales > 0
ORDER BY 
    r.total_sales DESC
LIMIT 100;
