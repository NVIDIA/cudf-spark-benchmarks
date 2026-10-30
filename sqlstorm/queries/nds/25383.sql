
WITH address_parts AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
), customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.full_address,
        a.ca_city,
        a.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN address_parts a ON c.c_current_addr_sk = a.ca_address_sk
), formatted_output AS (
    SELECT
        CONCAT('Customer: ', ci.full_name, ', Gender: ', ci.cd_gender,
               ', Marital Status: ', ci.cd_marital_status,
               ', Education: ', ci.cd_education_status,
               ', Address: ', ci.full_address, ', City: ', ci.ca_city,
               ', State: ', ci.ca_state) AS detailed_info
    FROM customer_info ci
)
SELECT 
    detailed_info
FROM formatted_output
WHERE detailed_info LIKE '%New York%'
ORDER BY detailed_info ASC
LIMIT 100;
