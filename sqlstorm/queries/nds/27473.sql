
WITH address_concat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address
    FROM 
        customer_address
),
demographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demo_info,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
marketing_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        d.demo_info,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        address_concat a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    m.customer_name,
    m.full_address,
    m.demo_info,
    m.cd_purchase_estimate,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count
FROM 
    marketing_data m
LEFT JOIN 
    sales_data s ON m.c_customer_sk = s.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
