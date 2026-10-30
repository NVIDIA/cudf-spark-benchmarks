
WITH AddressData AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerData AS (
    SELECT
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT
        c.full_name,
        c.c_email_address,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.order_count, 0) AS order_count,
        CASE 
            WHEN COALESCE(s.total_sales, 0) > 500 THEN 'High Value'
            WHEN COALESCE(s.total_sales, 0) BETWEEN 100 AND 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM CustomerData c
    JOIN AddressData a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT
    full_name,
    c_email_address,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    total_sales,
    order_count,
    customer_value
FROM CombinedData
WHERE customer_value = 'High Value'
ORDER BY total_sales DESC;
