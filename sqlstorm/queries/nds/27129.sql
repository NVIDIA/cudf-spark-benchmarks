
WITH AddressComponents AS (
    SELECT 
        ca_address_sk, 
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_suite_number, ca_city, ca_state, ca_zip) AS full_address,
        ca_country
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT_WS(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressComponents ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesStats AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        DemographicDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.full_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_spent,
    avg_order_value,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    SalesStats
ORDER BY 
    total_spent DESC;
