
WITH address_info AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ', ', ca_zip)) AS full_address,
        ca_country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c_current_cdemo_sk) AS demographics_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_country,
    si.total_sales,
    si.order_count,
    CASE 
        WHEN si.total_sales > 1000 THEN 'High Value Customer'
        WHEN si.total_sales BETWEEN 500 AND 1000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    customer_info ci
JOIN 
    address_info ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ai.ca_country = 'USA'
ORDER BY 
    total_sales DESC
LIMIT 100;
