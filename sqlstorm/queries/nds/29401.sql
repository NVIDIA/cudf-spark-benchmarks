
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('NY', 'CA') AND 
        cd.cd_marital_status = 'M'
),
EmailStatistics AS (
    SELECT 
        full_name, 
        email_length, 
        CASE 
            WHEN email_length < 20 THEN 'Short'
            WHEN email_length BETWEEN 20 AND 30 THEN 'Medium'
            ELSE 'Long'
        END AS email_category
    FROM 
        CustomerInfo
),
CountEmails AS (
    SELECT 
        email_category, 
        COUNT(*) AS category_count
    FROM 
        EmailStatistics
    GROUP BY 
        email_category
)
SELECT 
    email_category, 
    category_count,
    ROUND((category_count * 100.0 / SUM(category_count) OVER ()), 2) AS percentage
FROM 
    CountEmails
ORDER BY 
    email_category;
