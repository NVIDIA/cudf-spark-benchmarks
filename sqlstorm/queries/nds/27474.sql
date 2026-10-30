
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringProcessed AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        LOWER(CONCAT(c_first_name, ' ', c_last_name)) AS lower_full_name,
        UPPER(CONCAT(c_first_name, ' ', c_last_name)) AS upper_full_name,
        gender_rank
    FROM 
        RankedCustomers
)
SELECT 
    full_name,
    lower_full_name,
    upper_full_name,
    gender_rank,
    LENGTH(lower_full_name) AS name_length
FROM 
    StringProcessed
WHERE 
    gender_rank <= 10
ORDER BY 
    name_length DESC;
