
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
), 
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_sales cs
    INNER JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        (cs.total_store_sales + cs.total_web_sales) > 1000
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.cd_gender,
    h.cd_marital_status,
    h.cd_education_status,
    h.cd_purchase_estimate,
    h.cd_credit_rating,
    (h.total_store_sales + h.total_web_sales) AS total_sales,
    CASE 
        WHEN h.cd_gender = 'F' THEN 'Female'
        WHEN h.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender_description
FROM 
    high_value_customers h
ORDER BY 
    total_sales DESC
LIMIT 10;
