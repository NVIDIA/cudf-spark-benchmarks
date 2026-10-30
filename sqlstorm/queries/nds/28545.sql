
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, '')) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ap.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        AddressParts ap ON ca.ca_address_sk = ap.ca_address_sk
),
SalesData AS (
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
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.total_orders, 0) AS total_orders,
    LENGTH(ci.full_name) AS name_length,
    LENGTH(ci.full_address) AS address_length
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ci.ca_state = 'CA' 
ORDER BY 
    total_spent DESC
LIMIT 100;
