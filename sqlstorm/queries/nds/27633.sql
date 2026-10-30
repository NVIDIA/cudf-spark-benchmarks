
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        ca_state,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_credit_rating
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.city_upper,
    ai.ca_state,
    ai.zip_prefix,
    si.total_sales,
    si.total_orders
FROM CustomerDetails ci
JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE ai.city_upper LIKE 'A%' 
    AND ci.cd_marital_status = 'M'
ORDER BY total_sales DESC
LIMIT 10;
