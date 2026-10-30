
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(TRIM(ca_street_name)) AS normalized_street_name,
        REGEXP_REPLACE(ca_city, '[^A-Za-z ]', '') AS cleaned_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
address_counts AS (
    SELECT 
        normalized_street_name,
        COUNT(*) AS occurrence
    FROM 
        processed_addresses
    GROUP BY 
        normalized_street_name
    HAVING 
        COUNT(*) > 1
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.normalized_street_name,
        ca.cleaned_city,
        ca.full_address
    FROM 
        customer c
    JOIN 
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.cleaned_city,
    cd.normalized_street_name,
    COUNT(*) AS duplicate_addresses
FROM 
    customer_data cd
JOIN 
    address_counts ac ON cd.normalized_street_name = ac.normalized_street_name
GROUP BY 
    cd.full_name, cd.cleaned_city, cd.normalized_street_name
ORDER BY 
    duplicate_addresses DESC, cd.full_name;
