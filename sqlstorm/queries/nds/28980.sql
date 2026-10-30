
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(CASE WHEN cd_gender = 'M' THEN 'Mr. ' ELSE 'Ms. ' END, 
               CASE WHEN cd_marital_status = 'M' THEN 'Married ' ELSE 'Single ' END, 
               cd_education_status) AS customer_profile
    FROM customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    a.full_address,
    d.customer_profile,
    s.total_sales,
    s.total_orders
FROM AddressConcat a
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE s.total_sales > 1000
ORDER BY s.total_sales DESC
LIMIT 50;
