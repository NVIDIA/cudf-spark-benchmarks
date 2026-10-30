
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        LOWER(ca_city) AS city_lower,
        CONCAT(ca_state, ' ', ca_zip) AS state_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.full_address,
        a.city_lower,
        a.state_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        d.d_date AS ship_date,
        cd.customer_name,
        cd.city_lower,
        cd.state_zip
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_ship_customer_sk = cd.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
)
SELECT 
    COUNT(*) AS total_orders,
    SUM(ws_sales_price) AS total_sales,
    city_lower,
    state_zip
FROM 
    SalesData
GROUP BY 
    city_lower, state_zip
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_sales DESC;
