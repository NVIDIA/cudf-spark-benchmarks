
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM RankedCustomers rc
    WHERE rc.gender_rank <= 5
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip
),
CustomerLocation AS (
    SELECT 
        fc.full_name,
        fc.cd_gender,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.customer_count
    FROM FilteredCustomers fc
    JOIN AddressInfo ai ON fc.c_customer_sk = ai.ca_address_sk
)
SELECT 
    cl.ca_city,
    cl.ca_state,
    COUNT(DISTINCT cl.full_name) AS customer_count,
    SUM(cl.customer_count) AS total_customers,
    cl.cd_gender
FROM CustomerLocation cl
GROUP BY cl.ca_city, cl.ca_state, cl.cd_gender
ORDER BY cl.ca_state, cl.ca_city, cl.cd_gender;
