
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
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
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesWindow AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(total_web_sales, 0) AS web_sales,
        COALESCE(total_catalog_sales, 0) AS catalog_sales,
        COALESCE(total_store_sales, 0) AS store_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(total_web_sales, 0) DESC) AS sales_rank
    FROM 
        CustomerSales c
)

SELECT 
    s.c_first_name,
    s.c_last_name,
    s.web_sales,
    s.catalog_sales,
    s.store_sales,
    CASE 
        WHEN s.web_sales > 1000 THEN 'High Web Sales'
        WHEN s.web_sales BETWEEN 500 AND 1000 THEN 'Medium Web Sales'
        ELSE 'Low Web Sales'
    END AS web_sales_category,
    CASE 
        WHEN s.catalog_sales + s.store_sales > 10000 THEN 'High Store & Catalog Sales'
        ELSE 'Low Store & Catalog Sales'
    END AS store_catalog_sales_category
FROM 
    SalesWindow s
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.web_sales DESC, s.catalog_sales DESC;
