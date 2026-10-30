
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country)) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        a.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
AddressSummary AS (
    SELECT 
        full_address,
        COUNT(*) AS customer_count,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM 
        CustomerDetails
    GROUP BY 
        full_address
)
SELECT 
    full_address,
    customer_count,
    unique_customers,
    CASE 
        WHEN customer_count > 10 THEN 'High'
        WHEN customer_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS address_activity_level
FROM 
    AddressSummary
ORDER BY 
    customer_count DESC;
