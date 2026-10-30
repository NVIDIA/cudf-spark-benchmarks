
WITH CustomerFullNames AS (
    SELECT 
        c.c_customer_sk,
        TRIM(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS full_name,
        c.c_email_address AS email_address,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_zip AS zip,
        ca.ca_country AS country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_first_name IS NOT NULL 
        AND c.c_last_name IS NOT NULL
), BenchmarkedStrings AS (
    SELECT 
        cfn.c_customer_sk,
        cfn.full_name,
        cfn.email_address,
        cfn.city,
        cfn.state,
        cfn.zip,
        cfn.country,
        LENGTH(cfn.full_name) AS name_length,
        POSITION(' ' IN cfn.full_name) AS first_space_position,
        SUBSTRING(cfn.full_name, 1, POSITION(' ' IN cfn.full_name) - 1) AS first_name,
        REPLACE(cfn.full_name, ' ', '') AS name_no_spaces
    FROM 
        CustomerFullNames cfn
)
SELECT 
    b.c_customer_sk,
    b.full_name,
    b.email_address,
    b.city,
    b.state,
    b.zip,
    b.country,
    b.name_length,
    b.first_space_position,
    b.first_name,
    CASE 
        WHEN b.name_length > 20 THEN 'Long Name'
        ELSE 'Short Name' 
    END AS name_category,
    COUNT(*) OVER() AS total_records,
    CONCAT(b.first_name, '@example.com') AS email_with_first_name
FROM 
    BenchmarkedStrings b
ORDER BY 
    b.name_length DESC, 
    b.first_name ASC
LIMIT 100;
