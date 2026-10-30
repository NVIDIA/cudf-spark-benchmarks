WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_month, c.c_birth_day) as rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY', 'TX') 
        AND cd.cd_gender = 'F'
),
CustomerDetails AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.ca_city,
        rc.ca_state,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        LENGTH(rc.c_first_name || ' ' || rc.c_last_name) AS name_length
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 10  
)
SELECT 
    full_name,
    ca.ca_city,
    ca.ca_state,
    CASE 
        WHEN name_length > 30 THEN 'Long Name' 
        ELSE 'Short Name' 
    END AS name_category
FROM 
    CustomerDetails cd
JOIN 
    customer_address ca ON cd.c_customer_id = ca.ca_address_id
ORDER BY 
    ca.ca_state, name_length DESC;