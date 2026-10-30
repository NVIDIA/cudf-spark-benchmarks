
WITH address_info AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
demographic_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk = cd_demo_sk) AS customer_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 500
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS purchase_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    s.total_sales,
    s.purchase_count
FROM 
    customer c
JOIN 
    demographic_info d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    address_info a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    sales_info s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    d.customer_count > 1
ORDER BY 
    s.total_sales DESC
LIMIT 100;
