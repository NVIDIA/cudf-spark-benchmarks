
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
AggregateSales AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        NTILE(4) OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales)) AS sales_quartile
    FROM 
        CustomerSales
)
SELECT 
    sales_quartile,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM 
    AggregateSales
GROUP BY 
    sales_quartile
ORDER BY 
    sales_quartile;
