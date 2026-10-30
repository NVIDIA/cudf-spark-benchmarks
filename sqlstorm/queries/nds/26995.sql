
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.full_address,
        ca.address_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
),
address_summary AS (
    SELECT 
        full_address,
        COUNT(*) AS customer_count,
        AVG(address_length) AS avg_address_length
    FROM 
        filtered_customers
    GROUP BY 
        full_address
)
SELECT 
    full_address,
    customer_count,
    avg_address_length,
    CASE 
        WHEN customer_count > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS address_popularity
FROM 
    address_summary
ORDER BY 
    customer_count DESC, avg_address_length DESC;
