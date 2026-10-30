
WITH AddressAnalysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.max_street_name_length,
    a.min_street_name_length,
    a.avg_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate
FROM 
    AddressAnalysis a
JOIN 
    CustomerDemographics c ON a.ca_state = 'CA'
ORDER BY 
    a.unique_addresses DESC, 
    c.customer_count DESC;
