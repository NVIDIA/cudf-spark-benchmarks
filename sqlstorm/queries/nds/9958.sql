
WITH customer_sales AS (
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
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web Sales Leading'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog Sales Leading'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store Sales Leading'
            ELSE 'Sales Balanced'
        END AS sales_lead_type,
        COUNT(*) AS customer_count,
        SUM(total_web_sales) AS total_web_sales_sum,
        SUM(total_catalog_sales) AS total_catalog_sales_sum,
        SUM(total_store_sales) AS total_store_sales_sum
    FROM 
        customer_sales
    GROUP BY 
        sales_lead_type
)
SELECT 
    sales_lead_type,
    customer_count,
    total_web_sales_sum,
    total_catalog_sales_sum,
    total_store_sales_sum
FROM 
    sales_summary
ORDER BY 
    customer_count DESC;
