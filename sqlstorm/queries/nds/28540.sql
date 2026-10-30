
WITH formatted_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''))) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_zip) AS location
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        formatted_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.location,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
