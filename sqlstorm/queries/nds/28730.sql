
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_lower,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS gender_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.name_length,
        rc.gender_rank
    FROM 
        RankedCustomers rc
    WHERE 
        rc.name_length > 20 OR rc.cd_marital_status = 'M'
)
SELECT 
    fc.cd_gender,
    COUNT(*) AS customer_count,
    AVG(fc.name_length) AS avg_name_length,
    MIN(fc.full_name) AS first_alphabetical_name,
    MAX(fc.full_name) AS last_alphabetical_name
FROM 
    FilteredCustomers fc
GROUP BY 
    fc.cd_gender
ORDER BY 
    fc.cd_gender;
