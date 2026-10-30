
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
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
        c.c_customer_sk
), customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
), average_sales AS (
    SELECT 
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_education_status,
        AVG(sd.total_web_sales) AS avg_web_sales,
        AVG(sd.total_catalog_sales) AS avg_catalog_sales,
        AVG(sd.total_store_sales) AS avg_store_sales
    FROM 
        sales_summary sd
    GROUP BY 
        sd.cd_gender, 
        sd.cd_marital_status, 
        sd.cd_education_status
)
SELECT 
    avg_web_sales,
    avg_catalog_sales,
    avg_store_sales
FROM 
    average_sales
WHERE 
    avg_web_sales > 1000 AND avg_catalog_sales > 500
ORDER BY 
    avg_store_sales DESC
LIMIT 10;
