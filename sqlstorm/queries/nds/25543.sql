
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS formatted_location,
        ca_country AS country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    pa.full_address,
    pa.formatted_location,
    pa.country,
    ss.total_sales,
    ss.total_orders
FROM 
    customer_info ci
JOIN 
    processed_addresses pa ON ci.c_customer_sk = pa.ca_address_sk
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.total_sales > 1000 AND 
    ci.cd_marital_status = 'M'
ORDER BY 
    ss.total_sales DESC;
