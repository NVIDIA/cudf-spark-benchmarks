
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_customer_sk,
    r.income_band,
    r.cd_gender,
    r.cd_marital_status
FROM 
    RankedCustomers r
JOIN 
    customer c ON r.c_customer_sk = c.c_customer_sk
WHERE 
    r.rn <= 10 AND 
    (r.cd_marital_status = 'S' OR r.cd_gender = 'F')
ORDER BY 
    full_name;
