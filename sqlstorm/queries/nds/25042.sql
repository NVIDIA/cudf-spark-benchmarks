
WITH AddressEnhanced AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city, 
        ca_state
    FROM customer_address
),
CustomerEnhanced AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        ca_address_sk,
        full_address,
        ca_city,
        ca_state
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN AddressEnhanced ON c_current_addr_sk = ca_address_sk
),
DateAugmented AS (
    SELECT d_date_sk, d_date, d_month_seq, d_year, d_day_name
    FROM date_dim
    WHERE d_year = 2023
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_os,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        d.d_day_name
    FROM web_sales 
    JOIN DateAugmented d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY ws_bill_customer_sk, d.d_day_name
)
SELECT 
    C.full_name, 
    C.cd_gender, 
    C.cd_marital_status, 
    C.full_address, 
    C.ca_city, 
    C.ca_state, 
    S.total_sales,
    S.order_count,
    S.d_day_name
FROM CustomerEnhanced C
JOIN SalesData S ON C.c_customer_sk = S.customer_os
ORDER BY S.total_sales DESC, S.order_count DESC;
