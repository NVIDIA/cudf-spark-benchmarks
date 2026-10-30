
WITH processed_addresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
                  COALESCE(ca.ca_suite_number, '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_year,
        dm.cd_gender,
        dm.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
    JOIN 
        date_dim d ON c.c_birth_year = d.d_year
    WHERE 
        dm.cd_gender = 'F' AND dm.cd_marital_status = 'M'
)
SELECT 
    p.full_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    COUNT(*) AS address_count
FROM 
    filtered_customers p
JOIN 
    processed_addresses a ON p.c_customer_sk = a.ca_address_sk
GROUP BY 
    p.full_name, a.full_address, a.ca_city, a.ca_state, a.ca_zip, a.ca_country
HAVING 
    COUNT(*) > 1
ORDER BY 
    address_count DESC, p.full_name;
