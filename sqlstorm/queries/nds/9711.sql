
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_online_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesAggregate AS (
    SELECT 
        total_online_sales,
        total_catalog_sales,
        total_store_sales,
        (total_online_sales + total_catalog_sales + total_store_sales) AS total_sales,
        CASE 
            WHEN (total_online_sales + total_catalog_sales + total_store_sales) = 0 THEN 0 
            ELSE (total_online_sales / (total_online_sales + total_catalog_sales + total_store_sales)) * 100 
        END AS online_sales_percentage,
        CASE 
            WHEN (total_online_sales + total_catalog_sales + total_store_sales) = 0 THEN 0 
            ELSE (total_catalog_sales / (total_online_sales + total_catalog_sales + total_store_sales)) * 100 
        END AS catalog_sales_percentage,
        CASE 
            WHEN (total_online_sales + total_catalog_sales + total_store_sales) = 0 THEN 0 
            ELSE (total_store_sales / (total_online_sales + total_catalog_sales + total_store_sales)) * 100 
        END AS store_sales_percentage
    FROM 
        CustomerSales
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesAggregate
)
SELECT 
    online_sales_percentage,
    catalog_sales_percentage,
    store_sales_percentage
FROM 
    RankedSales
WHERE 
    sales_rank <= 10;
