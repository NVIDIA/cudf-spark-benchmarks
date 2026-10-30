
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TotalSales AS (
    SELECT 
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) > 10000 THEN 'High Spender' 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) > 5000 THEN 'Medium Spender' 
            ELSE 'Low Spender' 
        END AS customer_segment
    FROM 
        CustomerSales
),
SalesBySegment AS (
    SELECT 
        customer_segment, 
        COUNT(*) AS customer_count, 
        AVG(total_sales) AS avg_sales 
    FROM 
        TotalSales
    GROUP BY 
        customer_segment
)
SELECT 
    segment.customer_segment,
    segment.customer_count,
    segment.avg_sales,
    (SELECT COUNT(*) FROM customer) AS total_customers
FROM 
    SalesBySegment AS segment
ORDER BY 
    segment.customer_count DESC;
