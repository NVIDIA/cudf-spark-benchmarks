
WITH address_details AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CASE WHEN cd_gender = 'M' THEN 'Mr.' ELSE 'Ms.' END AS salutation,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.salutation,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    s.total_quantity,
    s.total_sales,
    s.total_orders
FROM 
    customer_details cd
JOIN 
    address_details ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    sales_info s ON cd.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    ad.ca_state = 'CA'
ORDER BY 
    s.total_sales DESC
LIMIT 100;
