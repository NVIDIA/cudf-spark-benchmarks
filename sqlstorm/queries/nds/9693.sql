
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
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
),
final_summary AS (
    SELECT 
        ss.c_customer_sk,
        ss.total_web_sales,
        ss.total_catalog_sales,
        ss.total_store_sales,
        ss.cd_gender,
        ss.cd_marital_status,
        ss.cd_education_status,
        CASE 
            WHEN ss.total_store_sales > 5000 THEN 'High Value Customer'
            WHEN ss.total_store_sales BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer'
        END AS customer_value_segment
    FROM 
        sales_summary ss
)
SELECT 
    fs.cd_gender,
    fs.cd_marital_status,
    fs.customer_value_segment,
    COUNT(*) AS customer_count,
    AVG(fs.total_web_sales) AS avg_web_sales,
    AVG(fs.total_catalog_sales) AS avg_catalog_sales,
    AVG(fs.total_store_sales) AS avg_store_sales
FROM 
    final_summary fs
GROUP BY 
    fs.cd_gender, fs.cd_marital_status, fs.customer_value_segment
ORDER BY 
    customer_count DESC;
