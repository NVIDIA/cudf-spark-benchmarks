
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_name,
        ca.ca_street_number,
        ca.ca_suite_number,
        ca.ca_location_type,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
        cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country, 
        ca.ca_zip, ca.ca_street_name, ca.ca_street_number, ca.ca_suite_number, ca.ca_location_type
),
AvgOrderValue AS (
    SELECT 
        c.c_customer_sk,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.ca_zip,
    ci.ca_street_name,
    ci.ca_street_number,
    ci.ca_suite_number,
    ci.ca_location_type,
    ci.total_orders,
    aov.avg_order_value,
    CASE 
        WHEN ci.total_orders = 0 THEN 'NO ORDERS'
        WHEN aov.avg_order_value > 100 THEN 'HIGH SPENDER'
        ELSE 'AVERAGE SPENDER'
    END AS customer_status
FROM 
    CustomerInfo ci
LEFT JOIN 
    AvgOrderValue aov ON ci.c_customer_sk = aov.c_customer_sk
ORDER BY 
    ci.total_orders DESC, aov.avg_order_value DESC
LIMIT 100;
