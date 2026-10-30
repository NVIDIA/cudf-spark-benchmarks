
WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        cd.cd_purchase_estimate AS purchase_estimate,
        c.c_customer_sk AS customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        COUNT(*) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_value,
        ws_bill_cdemo_sk AS customer_demo_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ci.full_name,
    ci.city,
    ci.state,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    ci.purchase_estimate,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales_value, 0) AS total_sales_value
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.customer_sk = ss.customer_demo_sk
WHERE 
    ci.city LIKE 'San%' AND 
    ci.marital_status = 'M' AND 
    ci.education_status LIKE '%graduate%'
ORDER BY 
    total_sales_value DESC
LIMIT 100;
