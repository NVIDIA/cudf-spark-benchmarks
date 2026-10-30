
WITH String_Analysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS domain,
        COUNT(DISTINCT ca.ca_address_id) AS num_addresses
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_first_name IS NOT NULL
        AND c.c_last_name IS NOT NULL
        AND c.c_email_address IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
Statistics AS (
    SELECT 
        AVG(name_length) AS avg_name_length,
        COUNT(*) AS total_customers,
        COUNT(DISTINCT domain) AS unique_domains
    FROM 
        String_Analysis
)
SELECT 
    s.avg_name_length,
    s.total_customers,
    s.unique_domains,
    (SELECT COUNT(*) FROM customer) AS total_records
FROM 
    Statistics s;
