
WITH ranked_addresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS rn
    FROM 
        customer_address
    WHERE 
        ca_city LIKE '%town%'
),
formatted_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state, ' - Address ID: ', ca_address_sk) AS full_address
    FROM 
        ranked_addresses
    WHERE 
        rn <= 5
)
SELECT 
    ca_address_sk,
    full_address,
    LENGTH(full_address) AS address_length,
    POSITION('Street' IN full_address) AS street_position,
    SUBSTRING(full_address, 1, 30) AS short_address
FROM 
    formatted_addresses
ORDER BY 
    address_length DESC;
