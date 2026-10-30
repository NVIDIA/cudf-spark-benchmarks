
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ai.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.customer_name,
        ci.full_address,
        si.total_quantity,
        si.total_spent
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    customer_name,
    full_address,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(total_spent, 0) = 0 THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Low Value Customer'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_spent DESC;
