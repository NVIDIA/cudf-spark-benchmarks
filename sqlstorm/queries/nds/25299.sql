
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FormattedDetails AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || full_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || full_name
            ELSE full_name
        END AS formatted_name
    FROM 
        CustomerDetails
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    formatted_name
FROM 
    FormattedDetails
WHERE 
    ca_state = 'CA'
GROUP BY 
    formatted_name
ORDER BY 
    total_customers DESC
LIMIT 10;
