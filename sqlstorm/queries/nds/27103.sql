
WITH customer_data AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS email,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education,
        cd_purchase_estimate AS purchase_estimate,
        ca_city AS city,
        ca_state AS state,
        ca_zip AS zip,
        c.c_customer_sk AS c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_report AS (
    SELECT 
        cd.full_name,
        cd.email,
        cd.gender,
        cd.marital_status,
        cd.education,
        cd.purchase_estimate,
        cd.city,
        cd.state,
        cd.zip,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_discount, 0) AS total_discount,
        COALESCE(ss.total_orders, 0) AS total_orders,
        cd.c_customer_sk
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    email,
    gender,
    marital_status,
    education,
    purchase_estimate,
    city,
    state,
    zip,
    total_sales,
    total_discount,
    total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    final_report
ORDER BY 
    total_sales DESC, full_name;
