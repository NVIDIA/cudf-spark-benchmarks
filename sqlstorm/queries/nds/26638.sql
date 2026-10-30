
SELECT 
    CONCAT(COALESCE(c.c_salutation, ''), ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CASE 
        WHEN cd.cd_purchase_estimate BETWEEN 0 AND 10000 THEN 'Low'
        WHEN cd.cd_purchase_estimate BETWEEN 10001 AND 50000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_band,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS state_purchase_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city LIKE '%Los Angeles%'
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
ORDER BY 
    purchase_estimate_band DESC, 
    full_name ASC;
