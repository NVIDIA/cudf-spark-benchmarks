
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
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
SalesAggregated AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'catalog'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'store'
            ELSE 'equal'
        END AS primary_sales_channel
    FROM 
        CustomerSales
)
SELECT 
    primary_sales_channel, 
    COUNT(*) AS customer_count,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    SalesAggregated
GROUP BY 
    primary_sales_channel
ORDER BY 
    customer_count DESC;
