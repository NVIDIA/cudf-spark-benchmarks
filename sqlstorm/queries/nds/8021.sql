
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 6)
    GROUP BY 
        ws_bill_cdemo_sk
),
demographics AS (
    SELECT 
        cd_demo_sk,
        MAX(cd_gender) AS gender,
        MAX(cd_marital_status) AS marital_status,
        MAX(cd_education_status) AS education_status,
        MAX(cd_credit_rating) AS credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ds.total_quantity,
        ds.total_sales,
        ds.total_discount,
        ds.order_count,
        d.gender,
        d.marital_status,
        d.education_status,
        d.credit_rating
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        sales_summary ds ON c.c_customer_sk = ds.ws_bill_cdemo_sk
    JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.total_sales,
    ci.total_discount,
    ci.order_count,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    ci.credit_rating
FROM 
    customer_info ci
WHERE 
    ci.total_sales > 1000
ORDER BY 
    ci.total_sales DESC
LIMIT 100;
