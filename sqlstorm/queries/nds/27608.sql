
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_name, 
        ca_city, 
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS rn
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
),
MaxStreetNameLength AS (
    SELECT 
        ca_city, 
        MAX(LENGTH(ca_street_name)) AS max_length
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
    GROUP BY 
        ca_city
)
SELECT 
    a.ca_address_id, 
    a.ca_street_name, 
    a.ca_city
FROM 
    RankedAddresses a
JOIN 
    MaxStreetNameLength m 
    ON a.ca_city = m.ca_city 
    AND LENGTH(a.ca_street_name) = m.max_length
WHERE 
    a.rn = 1
ORDER BY 
    a.ca_city, 
    a.ca_address_id;
