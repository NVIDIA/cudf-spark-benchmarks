
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END AS preferred_sales_channel,
        COUNT(c_customer_id) AS customer_count
    FROM 
        CustomerSales
    GROUP BY 
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END
)
SELECT 
    preferred_sales_channel,
    customer_count,
    ROUND((customer_count * 100.0) / SUM(customer_count) OVER (), 2) AS percentage_of_total_customers
FROM 
    SalesSummary
ORDER BY 
    customer_count DESC;
