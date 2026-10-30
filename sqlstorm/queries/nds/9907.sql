
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COALESCE(SUM(ws.ws_sales_price), 0) + COALESCE(SUM(cs.cs_sales_price), 0) + COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesAnalysis AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        total_sales,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        CustomerSales
)
SELECT 
    sales_quartile,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_web_sales) AS total_web_sales_sum,
    SUM(total_catalog_sales) AS total_catalog_sales_sum,
    SUM(total_store_sales) AS total_store_sales_sum
FROM 
    SalesAnalysis
GROUP BY 
    sales_quartile
ORDER BY 
    sales_quartile;
