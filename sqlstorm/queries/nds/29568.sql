
WITH address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) 
                    ELSE '' END) AS full_address,
        ca_city AS city,
        ca_state AS state,
        ca_zip AS zip,
        ca_country AS country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address AS email_address,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd_marital_status AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.email_address,
    ci.gender,
    ci.marital_status,
    ai.full_address,
    ai.city,
    ai.state,
    ai.zip,
    ai.country,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders
FROM 
    customer_info ci
LEFT JOIN 
    address_info ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ai.country = 'USA'
ORDER BY 
    total_sales DESC
LIMIT 100;
