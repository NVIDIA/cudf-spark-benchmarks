
WITH CustomerData AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS domain,
        CASE 
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedData AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        domain,
        purchase_estimate_category,
        COUNT(*) AS customer_count
    FROM 
        CustomerData
    GROUP BY 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        domain,
        purchase_estimate_category
)
SELECT 
    purchase_estimate_category,
    cd_gender,
    ca_state,
    SUM(customer_count) AS total_customers
FROM 
    AggregatedData
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    purchase_estimate_category,
    cd_gender,
    ca_state
ORDER BY 
    purchase_estimate_category, 
    cd_gender, 
    total_customers DESC;
