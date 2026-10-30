
WITH Address_Components AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type)) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
Customer_Details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN Address_Components ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CONCAT(full_address, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ' - ', ca_country) AS complete_address
FROM Customer_Details
WHERE cd_gender = 'F' AND ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country
ORDER BY full_name ASC;
