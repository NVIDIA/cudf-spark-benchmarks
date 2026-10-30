
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerDetails cd
    LEFT JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesDetails sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT * 
FROM FinalReport
WHERE total_sales > 1000 
ORDER BY total_sales DESC;
