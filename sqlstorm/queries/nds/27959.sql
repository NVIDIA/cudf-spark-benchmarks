
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
    GROUP BY 
        ca_city, 
        ca_state,
        ca_street_number, 
        ca_street_name, 
        ca_street_type
),
CustomerCancerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS average_dependents,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.full_address,
    a.address_count,
    cd.cd_gender,
    cd.customer_count,
    cd.average_dependents,
    cd.average_purchase_estimate
FROM 
    AddressDetails a
INNER JOIN 
    CustomerCancerDemographics cd ON a.ca_state = 'NY'
ORDER BY 
    a.address_count DESC, 
    cd.customer_count DESC
LIMIT 100;
