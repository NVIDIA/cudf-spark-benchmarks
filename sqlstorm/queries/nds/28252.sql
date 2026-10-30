
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_per_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
FilteredRanks AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank_per_gender <= 5
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
        JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    CONCAT(fr.c_first_name, ' ', fr.c_last_name) AS full_name,
    LENGTH(fr.c_first_name || ' ' || fr.c_last_name) AS full_name_length,
    CASE 
        WHEN UPPER(fr.cd_gender) = 'F' THEN 'Female'
        WHEN UPPER(fr.cd_gender) = 'M' THEN 'Male'
        ELSE 'Other' 
    END AS gender_description
FROM 
    FilteredRanks fr
JOIN 
    CustomerAddresses ca ON ca.ca_address_sk = fr.c_customer_sk
ORDER BY 
    fr.cd_marital_status, 
    full_name_length DESC;
