
WITH EnhancedCustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ca.ca_city || ', ' || ca.ca_state || ' - ' || ca.ca_zip AS full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_demo_sk DESC) AS demo_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    e.c_customer_id,
    e.c_first_name,
    e.c_last_name,
    e.gender,
    e.full_address,
    e.cd_purchase_estimate,
    e.cd_credit_rating
FROM 
    EnhancedCustomerData e
WHERE 
    e.demo_rank = 1
    AND e.cd_purchase_estimate > 5000
ORDER BY 
    e.cd_purchase_estimate DESC;
