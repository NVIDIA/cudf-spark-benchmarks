
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
address_count AS (
    SELECT 
        full_address,
        COUNT(*) AS address_count
    FROM 
        customer_info
    GROUP BY 
        full_address
    HAVING 
        COUNT(*) > 1
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ac.address_count
FROM 
    customer_info ci
JOIN 
    address_count ac ON ci.full_address = ac.full_address
ORDER BY 
    ac.address_count DESC, ci.customer_name;
