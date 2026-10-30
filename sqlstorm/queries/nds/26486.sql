
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(sr.sr_ticket_number) AS returns_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(sr.sr_ticket_number) DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('Bachelors', 'Masters', 'PhD')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)

SELECT 
    full_name, 
    cd_gender, 
    total_return_amt
FROM 
    RankedCustomers
WHERE 
    rn <= 5
ORDER BY 
    cd_gender, total_return_amt DESC;
