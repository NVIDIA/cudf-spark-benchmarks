
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name)) AS address_length
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.address_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.cd_gender,
    c.address_length,
    RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.address_length DESC) AS gender_rank
FROM CustomerDetails c
WHERE LENGTH(c.full_address) > 40
ORDER BY c.cd_gender, c.address_length DESC 
LIMIT 50;
