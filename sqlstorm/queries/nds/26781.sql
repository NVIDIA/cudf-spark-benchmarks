
WITH processed_addresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Apt ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM 
        customer_address
),
processed_demographics AS (
    SELECT 
        cd_demo_sk, 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unspecified' 
        END AS gender, 
        cd_marital_status, 
        cd_education_status
    FROM 
        customer_demographics
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.full_address,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_sales, 0) AS total_sales
FROM 
    processed_addresses ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    processed_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
ORDER BY 
    total_sales DESC, 
    ca.full_address;
