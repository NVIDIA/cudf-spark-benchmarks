
WITH enhanced_address AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END)) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip,
        TRIM(CONCAT(ca_country, ' (', ca_gmt_offset, ')')) AS country_details
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ea.full_address,
        ea.city,
        ea.state,
        ea.zip,
        ea.country_details
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        enhanced_address ea ON c.c_current_addr_sk = ea.ca_address_sk
),
purchase_stats AS (
    SELECT 
        ci.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price * ws_quantity) AS total_spent,
        AVG(ws_sales_price * ws_quantity) AS average_order_value
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ps.total_orders,
    ps.total_spent,
    ps.average_order_value,
    ci.full_address,
    ci.city,
    ci.state,
    ci.zip,
    ci.country_details
FROM 
    customer_info ci
LEFT JOIN 
    purchase_stats ps ON ci.c_customer_sk = ps.c_customer_sk
WHERE 
    ((ci.cd_gender = 'M' AND ps.total_spent > 1000) OR 
     (ci.cd_gender = 'F' AND ps.total_orders > 5))
ORDER BY 
    ci.city, ci.state, ps.total_spent DESC;
