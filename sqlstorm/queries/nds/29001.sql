
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressData ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ca.full_address,
    sa.total_sales,
    sa.order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sa ON ci.c_customer_sk = sa.customer_sk
JOIN 
    AddressData ca ON ci.ca_city = ca.ca_city AND ci.ca_state = ca.ca_state
WHERE 
    ci.cd_gender = 'M' 
    AND ci.cd_marital_status = 'S' 
    AND ci.ca_state = 'CA'
ORDER BY 
    sa.total_sales DESC
LIMIT 100;
