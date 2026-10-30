
WITH RankedAddresses AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city, ca_street_name) AS rnk
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        a.ca_address_id,
        a.ca_city,
        z.rnk
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        RankedAddresses z ON a.ca_address_id = z.ca_address_id
    WHERE 
        c.c_email_address LIKE '%@example.com'
)
SELECT 
    CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS full_name,
    ci.c_email_address,
    COUNT(DISTINCT ci.ca_address_id) AS distinct_addresses,
    MAX(ci.ca_city) AS city_alphabetically_last,
    MIN(ci.ca_city) AS city_alphabetically_first
FROM 
    CustomerInfo ci
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.c_email_address
HAVING 
    COUNT(DISTINCT ci.ca_address_id) > 1
ORDER BY 
    full_name;
