
WITH concatenated_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, 
                  COALESCE(ca_suite_number, ''), ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
purchase_summary AS (
    SELECT 
        ci.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ca.full_address,
    ps.total_sales,
    ps.total_orders
FROM 
    customer_info ci
JOIN 
    purchase_summary ps ON ci.c_customer_sk = ps.c_customer_sk
JOIN 
    concatenated_addresses ca ON ci.c_customer_sk = ca.ca_address_sk
WHERE 
    ps.total_sales > 1000
ORDER BY 
    ps.total_sales DESC;
