
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicStats AS (
    SELECT 
        cd_demo_sk,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dep_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk
)
SELECT 
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ac.ca_country,
    ds.customer_count,
    ds.avg_dep_count,
    ds.max_purchase_estimate
FROM 
    AddressComponents ac
LEFT JOIN 
    DemographicStats ds ON ac.ca_address_sk = ds.cd_demo_sk
WHERE 
    ac.ca_city IS NOT NULL
    AND ac.ca_state IN ('CA', 'TX', 'NY')
ORDER BY 
    ds.customer_count DESC
LIMIT 100;
