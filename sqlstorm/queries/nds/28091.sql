
WITH address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
demographics_info AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographics,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_address_sk,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    d.demographics,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    s.order_count,
    s.total_profit,
    s.total_revenue
FROM 
    address_info a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    demographics_info d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    sales_info s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    s.total_profit DESC
LIMIT 100;
