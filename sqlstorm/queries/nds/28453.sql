
WITH CustomerDetails AS (
    SELECT 
        CONCAT(cd_gender, ' ', c_first_name, ' ', c_last_name) AS full_name,
        ca_city,
        ca_state,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_marital_status,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk) AS total_demos
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd_purchase_estimate > 10000
),
IndexedNames AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        RANK() OVER (PARTITION BY ca_state ORDER BY cd_purchase_estimate DESC) AS rank
    FROM 
        CustomerDetails
)
SELECT 
    full_name, 
    ca_city, 
    ca_state 
FROM 
    IndexedNames 
WHERE 
    rank <= 10 
ORDER BY 
    ca_state, rank;
