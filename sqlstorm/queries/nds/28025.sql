
WITH AddressPrefix AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM customer_address
),
FilteredDemo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        LOWER(CAST(cd_purchase_estimate AS STRING)) AS purchase_estimate_str
    FROM customer_demographics
    WHERE cd_gender = 'M' AND cd_marital_status = 'S'
),
Combined AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.cd_education_status,
        d.purchase_estimate_str
    FROM customer c
    JOIN AddressPrefix a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN FilteredDemo d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    full_address,
    cd_gender,
    cd_education_status,
    LENGTH(purchase_estimate_str) AS estimate_length,
    UPPER(SUBSTRING(purchase_estimate_str, 1, 5)) AS estimate_prefix
FROM Combined
WHERE LENGTH(full_address) > 30
ORDER BY estimate_length DESC
LIMIT 100;
