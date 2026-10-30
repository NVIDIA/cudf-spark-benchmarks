
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(ca_city, ' ', '%') AS city_pattern,
        UPPER(ca_country) AS country_upper,
        LENGTH(ca_zip) AS zip_length
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
        d.cd_education_status,
        a.full_address,
        a.city_pattern,
        a.zip_length,
        CASE 
            WHEN d.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN d.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        processed_addresses AS a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    JOIN 
        customer_info AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    ss.total_sales,
    ss.order_count,
    ci.customer_value_segment
FROM 
    customer_info AS ci
LEFT JOIN 
    sales_summary AS ss ON ci.c_customer_sk = ss.c_customer_sk
WHERE 
    ci.city_pattern ILIKE '%NEW YORK%'
ORDER BY 
    ss.total_sales DESC NULLS LAST
LIMIT 50;
