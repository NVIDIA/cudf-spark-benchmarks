
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        COALESCE(total_web_sales, 0) AS total_web_sales, 
        COALESCE(total_catalog_sales, 0) AS total_catalog_sales, 
        COALESCE(total_store_sales, 0) AS total_store_sales,
        (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) AS overall_total_sales
    FROM 
        customer_sales c
)
SELECT 
    s.c_customer_sk, 
    s.c_first_name, 
    s.c_last_name,
    s.total_web_sales, 
    s.total_catalog_sales, 
    s.total_store_sales, 
    s.overall_total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    sales_summary s
JOIN customer_demographics cd ON s.c_customer_sk = cd.cd_demo_sk
WHERE 
    s.overall_total_sales > 1000
ORDER BY 
    overall_total_sales DESC
LIMIT 50;
