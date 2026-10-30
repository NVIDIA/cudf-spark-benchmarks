
WITH AddressData AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerData AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        c_current_addr_sk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    a.full_address,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count
FROM CustomerData c
JOIN AddressData a ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN SalesData s ON s.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    a.ca_state = 'NY' 
    AND c.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC, 
    c.c_last_name ASC, 
    c.c_first_name ASC
LIMIT 100;
