
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
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
AggregateSales AS (
    SELECT 
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END AS preferred_sales_channel,
        COUNT(*) AS customer_count,
        SUM(total_web_sales) AS total_web_revenue,
        SUM(total_catalog_sales) AS total_catalog_revenue,
        SUM(total_store_sales) AS total_store_revenue
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
    total_web_revenue,
    total_catalog_revenue,
    total_store_revenue,
    ROUND(total_web_revenue / NULLIF(customer_count, 0), 2) AS average_web_revenue_per_customer,
    ROUND(total_catalog_revenue / NULLIF(customer_count, 0), 2) AS average_catalog_revenue_per_customer,
    ROUND(total_store_revenue / NULLIF(customer_count, 0), 2) AS average_store_revenue_per_customer
FROM 
    AggregateSales
ORDER BY 
    customer_count DESC;
