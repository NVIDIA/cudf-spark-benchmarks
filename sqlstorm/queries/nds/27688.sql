
WITH AddressMetrics AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_country) AS country_length
    FROM customer_address
),
CustomerMetrics AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        SUBSTRING(c_email_address, POSITION('@' IN c_email_address) + 1) AS email_domain,
        LENGTH(c_first_name) AS first_name_length,
        LENGTH(c_last_name) AS last_name_length
    FROM customer
),
SalesMetrics AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_ext_sales_price) AS average_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cm.c_customer_sk,
    cm.c_first_name,
    cm.c_last_name,
    a.full_address,
    a.street_name_length,
    a.city_length,
    a.state_length,
    a.country_length,
    sm.total_sales,
    sm.order_count,
    sm.average_order_value
FROM CustomerMetrics cm
JOIN AddressMetrics a ON cm.c_customer_sk = a.ca_address_sk
LEFT JOIN SalesMetrics sm ON cm.c_customer_sk = sm.customer_sk
ORDER BY sm.total_sales DESC, a.city_length ASC
LIMIT 100;
