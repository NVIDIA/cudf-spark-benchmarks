
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT 
        *,
        CASE 
            WHEN city_rank <= 5 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        customer_info
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    cd_purchase_estimate,
    customer_type
FROM 
    top_customers
WHERE 
    ca_state = 'CA' 
    AND cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
ORDER BY 
    cd_purchase_estimate DESC;
