
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.c_email_address,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) as city_rank
    FROM 
        customer_address ca
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.c_email_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country
FROM 
    FilteredCustomers fc
JOIN 
    AddressInfo ai ON fc.c_customer_sk % 10 = ai.city_rank % 10
ORDER BY 
    fc.c_last_name, ai.ca_city;
