
WITH address_components AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT(ca_street_name, ' ', ca_street_type) AS full_street,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_location,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS complete_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        a.full_street,
        a.full_location,
        a.complete_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        address_components AS a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.full_location,
    c.cd_gender,
    c.cd_marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT CAST(ws.ws_item_sk AS STRING), ', ') AS purchased_items
FROM 
    customer_info AS c
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, c.full_location, c.cd_gender, c.cd_marital_status
ORDER BY 
    total_orders DESC
LIMIT 10;
