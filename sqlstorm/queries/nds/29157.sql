
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(REPLACE(ca_city, ' ', '')) AS city_cleaned,
        LOWER(REPLACE(ca_state, ' ', '')) AS state_cleaned,
        LOWER(REPLACE(ca_zip, ' ', '')) AS zip_cleaned
    FROM 
        customer_address
), 
DemoDetails AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '_', cd_marital_status) AS gender_marital,
        CASE 
            WHEN cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band
    FROM 
        customer_demographics
), 
DetailedCustomer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.gender_marital,
        d.purchase_band,
        a.full_address,
        a.city_cleaned,
        a.state_cleaned
    FROM 
        customer c
    JOIN 
        DemoDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    full_name,
    gender_marital,
    purchase_band,
    full_address,
    COUNT(*) OVER (PARTITION BY purchase_band) AS count_by_purchase_band,
    ROW_NUMBER() OVER (ORDER BY purchase_band, full_name) AS rn
FROM 
    DetailedCustomer
WHERE 
    city_cleaned LIKE '%york%'
    AND (state_cleaned = 'ny' OR state_cleaned = 'nj')
ORDER BY 
    purchase_band, rn;
