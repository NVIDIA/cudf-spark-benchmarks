
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        c.c_birth_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        si.total_quantity,
        si.total_sales,
        si.order_count,
        ci.c_birth_country,
        ci.full_address
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_ship_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0.00) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    c_birth_country,
    full_address
FROM 
    combined_info
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
