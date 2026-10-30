
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
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0) AS total_sales,
        CASE 
            WHEN SUM(total_web_sales) > 1000 THEN 'High Spender'
            WHEN SUM(total_web_sales) > 500 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END AS spender_category
    FROM 
        CustomerSales c
    GROUP BY 
        c.c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales
)
SELECT 
    s.c_customer_id,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.total_sales,
    s.spender_category
FROM 
    SalesSummary s
WHERE 
    s.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY 
    s.total_sales DESC
LIMIT 10;
