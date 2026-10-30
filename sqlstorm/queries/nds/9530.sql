
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer)
),
high_value_customers AS (
    SELECT 
        s.ws_bill_customer_sk,
        s.total_sales,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_credit_rating
    FROM 
        sales_summary s
    JOIN 
        demographics d ON s.ws_bill_customer_sk = d.cd_demo_sk
    WHERE 
        s.total_sales > 1000
)
SELECT 
    COUNT(*) AS high_value_count,
    AVG(total_sales) AS average_sales,
    COUNT(DISTINCT cd_gender) AS distinct_genders,
    COUNT(DISTINCT cd_marital_status) AS distinct_marital_statuses,
    COUNT(DISTINCT cd_education_status) AS distinct_education_statuses,
    COUNT(DISTINCT cd_credit_rating) AS distinct_credit_ratings
FROM 
    high_value_customers;
