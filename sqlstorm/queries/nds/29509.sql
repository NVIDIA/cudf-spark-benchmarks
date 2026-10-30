
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(c.c_email_address, ''), 'No Email') AS email,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
EmailStats AS (
    SELECT
        TRIM(SUBSTRING(email FROM 1 FOR 10)) AS email_prefix,
        COUNT(*) AS customer_count,
        MAX(gender_rank) AS max_rank
    FROM 
        RankedCustomers
    GROUP BY 
        email_prefix
),
FinalResults AS (
    SELECT 
        email_prefix,
        customer_count,
        max_rank,
        CASE 
            WHEN customer_count > 5 THEN 'High' 
            WHEN customer_count BETWEEN 3 AND 5 THEN 'Medium' 
            ELSE 'Low' 
        END AS customer_volume
    FROM 
        EmailStats
)
SELECT 
    email_prefix,
    customer_count,
    max_rank,
    customer_volume
FROM 
    FinalResults
ORDER BY 
    email_prefix ASC;
