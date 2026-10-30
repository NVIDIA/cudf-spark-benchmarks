
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name, c.c_first_name) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
),
CustomerInfo AS (
    SELECT 
        customer_rank,
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        ca_city,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CONCAT(ca_city, ', ', ca_state) AS full_address
    FROM RankedCustomers
)
SELECT 
    customer_rank,
    c_customer_id,
    full_name,
    cd_gender,
    full_address,
    LENGTH(full_name) AS name_length,
    UPPER(cd_gender) AS gender_upper
FROM CustomerInfo
WHERE customer_rank <= 10
ORDER BY ca_city, full_name;
