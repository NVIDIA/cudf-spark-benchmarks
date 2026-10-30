
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        RTRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_suite_number, ca_city, ca_state, ca_zip)) AS full_address,
        ca_country
    FROM 
        customer_address
),
DistCounts AS (
    SELECT 
        ca_country, 
        COUNT(DISTINCT LTRIM(RTRIM(full_address))) AS distinct_address_count
    FROM 
        AddressParts
    GROUP BY 
        ca_country
),
TopCountries AS (
    SELECT 
        ca_country, 
        distinct_address_count
    FROM 
        DistCounts
    WHERE 
        distinct_address_count > 10
    ORDER BY 
        distinct_address_count DESC
    LIMIT 5
)
SELECT 
    A.ca_country, 
    A.full_address, 
    D.distinct_address_count
FROM 
    AddressParts A
JOIN 
    TopCountries D 
ON 
    A.ca_country = D.ca_country
WHERE 
    LENGTH(A.full_address) > 50
ORDER BY 
    D.distinct_address_count DESC, A.full_address;
