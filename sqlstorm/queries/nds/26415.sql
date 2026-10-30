
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address
    FROM customer
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address AS email_address,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    COALESCE(si.total_sales, 0) AS total_sales
FROM CustomerInfo ci
JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE ai.ca_state = 'NY'
ORDER BY total_sales DESC
LIMIT 10;
