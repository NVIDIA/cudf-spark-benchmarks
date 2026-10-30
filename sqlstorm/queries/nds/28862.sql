
WITH StringAggregates AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || c.c_last_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || c.c_last_name 
            ELSE c.c_last_name 
        END AS formal_name,
        LENGTH(c.c_email_address) AS email_length,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name,
        REGEXP_REPLACE(c.c_email_address, '@.*$', '') AS email_prefix
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        c.c_birth_year > 1980
),
CityCounts AS (
    SELECT 
        ca_city, 
        COUNT(*) AS count_addresses 
    FROM 
        customer_address 
    GROUP BY 
        ca_city
),
CustomerSummary AS (
    SELECT 
        sa.c_customer_id, 
        sa.full_name, 
        sa.formal_name,
        cc.count_addresses,
        COUNT(DISTINCT sa.email_prefix) AS unique_email_prefixes
    FROM 
        StringAggregates sa 
    JOIN 
        customer_address ca ON sa.full_name LIKE CONCAT('%', ca.ca_city, '%')
    JOIN 
        CityCounts cc ON ca.ca_city = cc.ca_city
    GROUP BY 
        sa.c_customer_id, sa.full_name, sa.formal_name, cc.count_addresses
)
SELECT 
    * 
FROM 
    CustomerSummary 
ORDER BY 
    unique_email_prefixes DESC, 
    count_addresses DESC;
