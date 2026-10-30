
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_country AS country,
        SUBSTRING(ca.ca_zip, 1, 5) AS zip_prefix,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender,
             cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country, ca.ca_zip
)
SELECT 
    full_name,
    gender,
    marital_status,
    education_status,
    city,
    state,
    country,
    zip_prefix,
    total_purchases,
    total_spent,
    CASE 
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM customer_data
WHERE total_purchases > 5
ORDER BY total_spent DESC, full_name ASC;
