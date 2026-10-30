
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
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
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        ca.ca_country
    FROM 
        customer_demographics cd
    JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
),
summary AS (
    SELECT 
        cs.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_credit_rating,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        CASE 
            WHEN cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales > 1000 THEN 'High Value'
            WHEN cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_sales cs
    JOIN 
        demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    customer_value,
    COUNT(*) AS customer_count,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    summary
GROUP BY 
    customer_value
ORDER BY 
    customer_value;
