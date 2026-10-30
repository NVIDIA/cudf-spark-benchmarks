
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM 
        customer_demographics AS cd
    JOIN 
        catalog_sales AS cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales,
    dm.total_catalog_sales,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status
FROM 
    customer_sales AS cs
JOIN 
    demographics AS dm ON cs.c_customer_sk = dm.cd_demo_sk
WHERE 
    cs.total_web_sales > 1000
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC
LIMIT 50;
