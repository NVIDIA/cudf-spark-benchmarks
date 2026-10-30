
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TotalSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        COALESCE(c.total_web_sales, 0) AS web_sales_value,
        COALESCE(c.total_catalog_sales, 0) AS catalog_sales_value,
        COALESCE(c.total_store_sales, 0) AS store_sales_value,
        (COALESCE(c.total_web_sales, 0) + COALESCE(c.total_catalog_sales, 0) + COALESCE(c.total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales c
),
Ranking AS (
    SELECT 
        customer_id,
        web_sales_value,
        catalog_sales_value,
        store_sales_value,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        TotalSales
)
SELECT 
    customer_id,
    web_sales_value,
    catalog_sales_value,
    store_sales_value,
    total_sales,
    sales_rank
FROM 
    Ranking
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
