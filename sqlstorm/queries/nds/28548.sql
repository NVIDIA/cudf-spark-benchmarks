
WITH customer_fullnames AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
address_details AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
string_benchmark AS (
    SELECT
        cfn.full_name,
        ad.full_address,
        LENGTH(cfn.full_name) AS name_length,
        LENGTH(ad.full_address) AS address_length,
        LOWER(cfn.full_name) AS lower_full_name,
        UPPER(ad.full_address) AS upper_full_address,
        REPLACE(LOWER(cfn.full_name), ' ', '-') AS name_with_hyphens,
        SUBSTRING(ad.full_address, 1, 30) AS short_address,
        POSITION(' ' IN cfn.full_name) AS first_space_position,
        REVERSE(cfn.full_name) AS reversed_name
    FROM 
        customer_fullnames cfn
    JOIN 
        customer_address ca ON ca.ca_address_sk = cfn.c_customer_sk
    JOIN 
        address_details ad ON ad.ca_address_sk = ca.ca_address_sk
)
SELECT 
    full_name, 
    full_address, 
    name_length, 
    address_length, 
    lower_full_name, 
    upper_full_address, 
    name_with_hyphens, 
    short_address, 
    first_space_position, 
    reversed_name
FROM 
    string_benchmark
ORDER BY 
    name_length DESC, address_length DESC
LIMIT 100;
