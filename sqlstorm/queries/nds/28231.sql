
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
purchase_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_ext_sales_price) AS total_spent,
        AVG(ss.ss_ext_sales_price) AS avg_order_value
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ci.full_name,
    ai.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ps.total_purchases,
    ps.total_spent,
    ps.avg_order_value
FROM 
    customer_info ci
JOIN 
    address_info ai ON ci.c_customer_id = ai.ca_address_id
LEFT JOIN 
    purchase_summary ps ON ci.c_customer_id = ps.c_customer_id
WHERE 
    ci.first_purchase_date >= '2022-01-01' 
    AND ci.cd_gender = 'F' 
ORDER BY 
    ps.total_spent DESC
LIMIT 100;
