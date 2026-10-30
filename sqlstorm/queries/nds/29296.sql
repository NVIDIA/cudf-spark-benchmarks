
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
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
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
DetailedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        sd.total_quantity,
        sd.total_sales
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressDetails ca ON ca.ca_address_sk = ci.c_customer_sk
    LEFT JOIN 
        SalesData sd ON sd.ws_ship_customer_sk = ci.c_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales >= 1000 THEN 'High Value Customer'
        WHEN total_sales >= 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    DetailedInfo
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC;
