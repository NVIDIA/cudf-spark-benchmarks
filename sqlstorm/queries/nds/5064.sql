
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
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SaleSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web Sales'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog Sales'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store Sales'
            ELSE 'Equal Sales'
        END AS top_sales_channel
    FROM 
        CustomerSales AS c
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.top_sales_channel
FROM 
    SaleSummary AS s
WHERE 
    (s.total_web_sales + s.total_catalog_sales + s.total_store_sales) > 1000
ORDER BY 
    s.total_web_sales DESC, 
    s.total_catalog_sales DESC, 
    s.total_store_sales DESC
LIMIT 100;
