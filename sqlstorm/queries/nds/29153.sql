
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM customer_address ca
)
SELECT 
    rc.c_customer_id,
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state
FROM RankedCustomers rc
JOIN AddressInfo ai ON rc.rank = 1
WHERE ai.ca_state = 'CA'
ORDER BY ai.ca_city, rc.full_name;
