
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cu.ca_city,
        c.c_birth_year,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_by_age
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address cu ON c.c_current_addr_sk = cu.ca_address_sk
)
SELECT 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.cd_gender, 
    rc.cd_marital_status, 
    rc.ca_city,
    LENGTH(CONCAT(rc.c_first_name, ' ', rc.c_last_name)) AS full_name_length,
    CONCAT(UPPER(SUBSTRING(rc.c_first_name, 1, 1)), LOWER(SUBSTRING(rc.c_first_name, 2))) AS formatted_first_name,
    CONCAT(UPPER(SUBSTRING(rc.c_last_name, 1, 1)), LOWER(SUBSTRING(rc.c_last_name, 2))) AS formatted_last_name
FROM RankedCustomers rc
WHERE rc.rank_by_age <= 10
GROUP BY 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.cd_gender, 
    rc.cd_marital_status, 
    rc.ca_city,
    rc.c_birth_year
ORDER BY rc.cd_gender, rc.c_birth_year DESC;
