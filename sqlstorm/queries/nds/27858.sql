
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        (CASE 
            WHEN ca.ca_state IN ('NY', 'CA') THEN 'High Value'
            WHEN ca.ca_state IN ('TX', 'FL') THEN 'Medium Value'
            ELSE 'Low Value'
        END) AS area_value
    FROM customer_address ca
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ad.ca_street_name,
    ad.ca_city,
    ad.ca_state,
    ad.area_value
FROM RankedCustomers rc
JOIN AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
WHERE rc.rnk <= 10
ORDER BY rc.cd_gender, rc.cd_marital_status, rc.cd_education_status;
