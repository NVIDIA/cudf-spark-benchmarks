
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
CustomerConcat AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name, ' (', c_email_address, ')') AS full_customer_info
    FROM 
        customer
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_customer_info,
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    COALESCE(s.total_sales, 0) AS total_sales,
    s.order_count
FROM 
    CustomerConcat c
JOIN 
    AddressConcat a ON c.c_customer_sk = a.ca_address_sk
JOIN 
    Demographics d ON c.c_customer_sk = d.cd_demo_sk
LEFT JOIN 
    SalesStats s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    d.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC
LIMIT 50;
