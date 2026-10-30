
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca.ca_suite_number)) ELSE '' END, 
               ', ', TRIM(ca.ca_city), ', ', TRIM(ca.ca_state), ' ', TRIM(ca.ca_zip)) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        processed_customers c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    pc.full_name,
    pc.full_address,
    pc.cd_gender,
    pc.cd_marital_status,
    pc.cd_education_status,
    pc.cd_purchase_estimate,
    pc.cd_credit_rating,
    pc.cd_dep_count,
    ss.total_orders,
    ss.total_sales,
    ss.avg_order_value
FROM 
    processed_customers pc
LEFT JOIN 
    sales_summary ss ON pc.c_customer_sk = ss.c_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
