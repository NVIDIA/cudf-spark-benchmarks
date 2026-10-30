
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUBSTRING(c.c_email_address FROM 1 FOR POSITION('@' IN c.c_email_address) - 1) AS email_prefix
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
merged_info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.order_count,
        si.total_quantity
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count,
    total_quantity,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Sales'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    merged_info
WHERE 
    ca_state = 'CA' 
ORDER BY 
    total_sales DESC
LIMIT 100;
