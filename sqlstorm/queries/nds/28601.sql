
WITH String_Benchmarking AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS address_length,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS customer_name_length,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ca.ca_city LIKE '%ville%' AND
        cd.cd_gender = 'F'
),
Aggregated_Results AS (
    SELECT
        COUNT(*) AS total_addresses,
        AVG(address_length) AS avg_address_length,
        AVG(customer_name_length) AS avg_customer_name_length,
        cd_gender,
        cd_marital_status
    FROM 
        String_Benchmarking
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    *,
    RANK() OVER (ORDER BY avg_address_length DESC) AS length_rank
FROM 
    Aggregated_Results
ORDER BY 
    total_addresses DESC, length_rank;
