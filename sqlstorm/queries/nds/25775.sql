
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address,
        LENGTH(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country)) AS address_length,
        REGEXP_REPLACE(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country), '\\s+', ' ') AS compact_address
    FROM 
        customer_address
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        da.full_address,
        da.address_length,
        da.compact_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        processed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    ci.address_length,
    ci.compact_address,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_web_sales
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.full_address, 
    ci.address_length, 
    ci.compact_address, 
    ci.cd_gender, 
    ci.cd_marital_status
ORDER BY 
    total_web_sales DESC
LIMIT 50;
