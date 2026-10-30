
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), ''), ', ', 
               ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
matched_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        a.full_address
    FROM 
        customer c
    JOIN 
        processed_addresses a ON c.c_current_addr_sk = a.ca_address_sk
),
gender_analysis AS (
    SELECT 
        m.c_customer_sk,
        m.c_first_name,
        m.c_last_name,
        d.cd_gender,
        LENGTH(m.full_address) AS address_length
    FROM 
        matched_customers m
    JOIN 
        customer_demographics d ON m.c_customer_sk = d.cd_demo_sk
)
SELECT 
    cd_gender AS gender,
    COUNT(*) AS total_customers,
    AVG(address_length) AS avg_address_length,
    MIN(address_length) AS min_address_length,
    MAX(address_length) AS max_address_length
FROM 
    gender_analysis
GROUP BY 
    cd_gender
ORDER BY 
    gender;
