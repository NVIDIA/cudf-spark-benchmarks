
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(UPPER(CONCAT(ca_city, ', ', ca_state))) AS city_state,
        REPLACE(ca_zip, '-', '') AS clean_zip,
        LENGTH(ca_country) AS country_length
    FROM 
        customer_address
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        processed_addresses.full_address,
        processed_addresses.city_state,
        processed_addresses.clean_zip,
        processed_addresses.country_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses ON c.c_current_addr_sk = processed_addresses.ca_address_sk
),
sales_summary AS (
    SELECT 
        ca.full_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer_analysis ca
    JOIN 
        web_sales ws ON ca.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.full_name
)
SELECT 
    full_name,
    total_orders,
    total_spent,
    avg_order_value,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value Customer'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    sales_summary
ORDER BY 
    total_spent DESC
LIMIT 50;
