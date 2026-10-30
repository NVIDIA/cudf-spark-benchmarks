
WITH customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        cp.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cp.total_web_sales,
        cp.total_store_sales,
        COALESCE(cp.total_web_sales, 0) + COALESCE(cp.total_store_sales, 0) AS total_sales
    FROM 
        customer_purchases cp
    JOIN 
        customer_details cd ON cp.c_customer_sk = cd.c_customer_sk
)
SELECT 
    ss.c_first_name,
    ss.c_last_name,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.cd_education_status,
    ss.total_web_sales,
    ss.total_store_sales,
    ss.total_sales,
    DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM 
    sales_summary ss
WHERE 
    ss.total_sales > 1000
ORDER BY 
    sales_rank
LIMIT 50;
