
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
    WHERE ca_country = 'USA'
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate > 10000
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ac.full_address,
        dd.d_date AS first_purchase_date,
        dd.d_month_seq AS purchase_month,
        dd.d_year AS purchase_year,
        dcd.cd_gender,
        dcd.cd_marital_status
    FROM customer c
    JOIN AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
    JOIN DemographicDetails dcd ON c.c_current_cdemo_sk = dcd.cd_demo_sk
    JOIN date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.full_address,
    c.purchase_month,
    c.purchase_year,
    COUNT(CASE WHEN c.cd_gender = 'F' THEN 1 END) AS female_customers,
    COUNT(CASE WHEN c.cd_gender = 'M' THEN 1 END) AS male_customers,
    MIN(c.first_purchase_date) AS earliest_purchase,
    MAX(c.first_purchase_date) AS latest_purchase
FROM CustomerInfo c
GROUP BY c.full_address, c.purchase_month, c.purchase_year, c.c_first_name, c.c_last_name
ORDER BY c.purchase_year, c.purchase_month;
