
WITH AddressInfo AS (
    SELECT 
        ca_addr.ca_address_id,
        CONCAT_WS(' ', ca_addr.ca_street_number, ca_addr.ca_street_name, ca_addr.ca_street_type, ca_addr.ca_suite_number) AS full_address,
        ca_addr.ca_city,
        ca_addr.ca_state
    FROM customer_address ca_addr
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReviewInfo AS (
    SELECT 
        c.c_customer_id,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS review_rank
    FROM customer c
    JOIN date_dim d ON c.c_last_review_date_sk = d.d_date_sk
),
FinalOutput AS (
    SELECT 
        ci.full_name,
        ci.c_birth_country,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ri.review_rank
    FROM CustomerInfo ci
    JOIN ReviewInfo ri ON ci.c_customer_id = ri.c_customer_id
    JOIN AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
)
SELECT 
    full_name,
    c_birth_country,
    cd_gender,
    cd_marital_status,
    CONCAT(full_address, ', ', ca_city, ', ', ca_state) AS complete_address,
    review_rank
FROM FinalOutput
WHERE review_rank = 1
ORDER BY full_name;
