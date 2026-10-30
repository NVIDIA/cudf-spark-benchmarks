
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS number_of_sales
    FROM store_sales
    GROUP BY ss_customer_sk
),
CombinedData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        sd.total_sales,
        sd.number_of_sales
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ss_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(number_of_sales, 0) AS number_of_sales,
    CASE 
        WHEN total_sales >= 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CombinedData
ORDER BY total_sales DESC
LIMIT 100;
