
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(c.c_birth_month, 1) AS birth_month,
        COALESCE(c.c_birth_year, 1900) AS birth_year,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 

CustomerDetails AS (
    SELECT
        rc.full_name,
        CASE 
            WHEN EXTRACT(MONTH FROM DATE '2002-10-01') = rc.birth_month AND EXTRACT(DAY FROM DATE '2002-10-01') = 1 THEN 'Happy Birthday!'
            ELSE 'Have a great day!'
        END AS birthday_greeting,
        CASE 
            WHEN rc.cd_marital_status = 'M' THEN 'Married'
            WHEN rc.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 10 
)

SELECT 
    cd.full_name,
    cd.birthday_greeting,
    cd.marital_status
FROM 
    CustomerDetails cd
ORDER BY 
    cd.full_name;
