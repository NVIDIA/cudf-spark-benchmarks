
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA'
)

SELECT 
    ca_city,
    ARRAY_AGG(c_customer_id) AS customer_ids,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    CustomerDetails
WHERE 
    rank <= 5
GROUP BY 
    ca_city
ORDER BY 
    avg_purchase_estimate DESC;
