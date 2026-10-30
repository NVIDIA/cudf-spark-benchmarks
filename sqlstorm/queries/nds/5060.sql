
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
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
SalesComparison AS (
    SELECT 
        c.c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web Sales'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog Sales'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store Sales'
            ELSE 'Equal Sales'
        END AS top_sales_channel
    FROM 
        CustomerSales c
)
SELECT 
    top_sales_channel,
    COUNT(*) AS customer_count,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    SalesComparison
GROUP BY 
    top_sales_channel
ORDER BY 
    customer_count DESC;
