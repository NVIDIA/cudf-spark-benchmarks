
WITH address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
demographics_info AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.gender_status,
    d.cd_education_status,
    s.total_spent,
    s.total_orders
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
    AND d.cd_purchase_estimate > 1000
ORDER BY 
    s.total_spent DESC
LIMIT 50;
