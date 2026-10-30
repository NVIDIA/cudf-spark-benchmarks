
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT c.c_customer_sk) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        'Web' AS sale_channel,
        total_web_sales AS total_sales,
        purchase_count
    FROM 
        CustomerSales
    WHERE 
        total_web_sales IS NOT NULL

    UNION ALL

    SELECT 
        'Catalog' AS sale_channel,
        total_catalog_sales AS total_sales,
        purchase_count
    FROM 
        CustomerSales
    WHERE 
        total_catalog_sales IS NOT NULL

    UNION ALL

    SELECT 
        'Store' AS sale_channel,
        total_store_sales AS total_sales,
        purchase_count
    FROM 
        CustomerSales
    WHERE 
        total_store_sales IS NOT NULL
)
SELECT 
    sale_channel,
    SUM(total_sales) AS total_sales_value,
    AVG(purchase_count) AS average_purchases
FROM 
    SalesSummary
GROUP BY 
    sale_channel
ORDER BY 
    total_sales_value DESC;
