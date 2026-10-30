
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
StringMetrics AS (
    SELECT 
        LENGTH(customer_full_name) AS name_length,
        LENGTH(c_email_address) AS email_length,
        cd_gender,
        cd_marital_status,
        ca_city,
        ca_state
    FROM 
        CustomerInfo
),
BenchmarkStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        ca_city,
        ca_state,
        AVG(name_length) AS avg_name_length,
        AVG(email_length) AS avg_email_length,
        MIN(name_length) AS min_name_length,
        MAX(name_length) AS max_name_length,
        MIN(email_length) AS min_email_length,
        MAX(email_length) AS max_email_length
    FROM 
        StringMetrics
    GROUP BY 
        cd_gender, cd_marital_status, ca_city, ca_state
)
SELECT 
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    avg_name_length,
    avg_email_length,
    min_name_length,
    max_name_length,
    min_email_length,
    max_email_length,
    CASE 
        WHEN avg_name_length > 20 THEN 'Long Names' 
        ELSE 'Short Names' 
    END AS name_length_category,
    CASE 
        WHEN avg_email_length > 25 THEN 'Long Emails' 
        ELSE 'Short Emails' 
    END AS email_length_category
FROM 
    BenchmarkStats
ORDER BY 
    ca_city, cd_gender, avg_name_length DESC;
