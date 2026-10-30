
WITH Address_Details AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_country
    FROM 
        customer_address
),
Customer_Demographic AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM 
        customer_demographics
),
Customer_Info AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_email_address,
        ca.ca_country AS country,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education
    FROM 
        customer c
    JOIN 
        Address_Details ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        Customer_Demographic cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.country,
    ci.city,
    ci.state,
    ci.gender,
    ci.marital_status,
    ci.education,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders,
    CASE 
        WHEN si.total_sales > 5000 THEN 'High Value'
        WHEN si.total_sales > 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    Customer_Info ci
LEFT JOIN 
    Sales_Info si ON ci.c_customer_sk = si.ws_bill_customer_sk
ORDER BY 
    total_sales DESC;
