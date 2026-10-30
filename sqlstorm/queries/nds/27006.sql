
WITH AddressDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_address_sk DESC) AS address_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    ad.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.cd_education_status,
    CASE 
        WHEN ad.cd_purchase_estimate < 50000 THEN 'Low Buyer'
        WHEN ad.cd_purchase_estimate BETWEEN 50000 AND 150000 THEN 'Medium Buyer'
        ELSE 'High Buyer'
    END AS buyer_category
FROM 
    AddressDetails ad
WHERE 
    ad.address_rank = 1
AND 
    ad.ca_state IN ('CA', 'NY')
AND 
    ad.cd_gender = 'F'
ORDER BY 
    ad.full_name;
