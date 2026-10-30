
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_sales_price) AS total_sales_value
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    s.total_quantity_sold,
    s.total_sales_value
FROM AddressInfo a
JOIN CustomerDetails c ON a.ca_address_sk = c.c_customer_sk
JOIN SalesSummary s ON a.ca_address_sk = s.ss_store_sk
WHERE a.ca_country = 'USA' 
AND s.total_sales_value > 1000
ORDER BY a.ca_state, s.total_sales_value DESC;
