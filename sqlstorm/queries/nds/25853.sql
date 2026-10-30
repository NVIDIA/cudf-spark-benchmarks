
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(ca_street_name)) AS normalized_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
detailed_report AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sa.full_address,
        COALESCE(si.total_spent, 0) AS total_spent,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        processed_addresses sa ON ci.c_customer_sk = sa.ca_address_sk
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    ORDER BY 
        total_spent DESC
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    detailed_report;
