
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ci.full_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_hdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Info ci ON c.c_current_addr_sk = ci.ca_address_sk
),
Sales_Info AS (
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
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    si.total_sales,
    si.order_count,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country
FROM 
    Customer_Info ci
LEFT JOIN 
    Sales_Info si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, 
    ci.full_name ASC
LIMIT 50;
