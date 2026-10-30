
WITH ranked_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
demographic_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT('Estimated Purchase: $', cd_purchase_estimate) AS purchase_description
    FROM 
        customer_demographics
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.cd_gender,
    d.cd_marital_status,
    d.purchase_description
FROM 
    ranked_addresses a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    demographic_info d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    a.address_rank <= 5
ORDER BY 
    a.ca_city, a.full_address;
