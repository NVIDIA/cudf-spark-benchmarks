
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE 
            WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_ext_sales_price 
            ELSE 0 
        END) AS web_sales,
        SUM(CASE 
            WHEN cs.cs_ship_date_sk IS NOT NULL THEN cs.cs_ext_sales_price 
            ELSE 0 
        END) AS catalog_sales,
        SUM(CASE 
            WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_ext_sales_price 
            ELSE 0 
        END) AS store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        SUM(web_sales) AS total_web_sales,
        SUM(catalog_sales) AS total_catalog_sales,
        SUM(store_sales) AS total_store_sales,
        COUNT(c_customer_id) AS customer_count
    FROM 
        CustomerSales
)
SELECT 
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    customer_count,
    (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
    ROUND((total_web_sales + total_catalog_sales + total_store_sales) / customer_count, 2) AS average_sales_per_customer
FROM 
    SalesSummary;
