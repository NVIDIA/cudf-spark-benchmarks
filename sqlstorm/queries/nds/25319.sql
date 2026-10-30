
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FullAddress AS (
    SELECT 
        ca.ca_address_sk AS c_customer_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS complete_address
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    fa.complete_address,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerInfo ci
LEFT JOIN 
    FullAddress fa ON ci.c_customer_sk = fa.c_customer_sk
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    total_spent DESC
LIMIT 100;
