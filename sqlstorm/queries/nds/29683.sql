
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM customer_address ca 
    JOIN RankedCustomers rc ON ca.ca_address_sk = rc.c_customer_sk
),
StringMetrics AS (
    SELECT 
        full_name,
        CHAR_LENGTH(full_name) AS name_length,
        REPLACE(LOWER(full_name), ' ', '') AS cleaned_name,
        COUNT(*) OVER () AS total_customers
    FROM CustomerAddresses
)

SELECT 
    cm.full_name,
    cm.name_length,
    cm.cleaned_name,
    cm.total_customers,
    fl.first_letters,
    REPEAT(fl.first_letters, 2) AS repeated_letters,
    SUBSTRING(cleaned_name FROM 1 FOR 1) AS first_character,
    CHAR_LENGTH(cleaned_name) - CHAR_LENGTH(REPLACE(cleaned_name, 'e', '')) AS count_e
FROM StringMetrics cm
JOIN (SELECT DISTINCT LEFT(cleaned_name, 1) AS first_letters FROM StringMetrics) fl ON TRUE
WHERE cm.total_customers > 0
ORDER BY cm.name_length DESC;
