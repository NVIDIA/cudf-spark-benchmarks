
WITH AddressParts AS (
    SELECT ca_address_sk,
           TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
           SUBSTRING(ca_city, 1, 3) AS city_abbr,
           ca_state AS state_abbr,
           ca_zip AS zip_code,
           ca_country AS country_name
    FROM customer_address
),
CustomerInfo AS (
    SELECT c.c_customer_sk,
           CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
           d.d_date AS last_purchase_date,
           CASE 
               WHEN cd.cd_gender = 'M' THEN 'Male'
               WHEN cd.cd_gender = 'F' THEN 'Female'
               ELSE 'Other' 
           END AS gender,
           ib.ib_lower_bound, 
           ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_date >= DATE '2023-01-01'
),
AddressCustomer AS (
    SELECT a.full_address,
           c.full_name,
           c.gender,
           c.last_purchase_date,
           CONCAT(a.city_abbr, ' ', a.state_abbr, ' ', a.zip_code, ' ', a.country_name) AS location_info 
    FROM AddressParts a
    JOIN CustomerInfo c ON a.ca_address_sk = c.c_customer_sk
)
SELECT full_address,
       full_name,
       gender,
       last_purchase_date,
       location_info
FROM AddressCustomer
ORDER BY last_purchase_date DESC
LIMIT 100;
