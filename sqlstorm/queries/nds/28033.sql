
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY c.c_last_name, c.c_first_name) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') OR 
        (cd.cd_gender = 'M' AND cd.cd_marital_status = 'S')
),
ProcessedCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        rc.ca_city,
        rc.ca_state,
        LOWER(CONCAT(rc.c_last_name, ', ', rc.c_first_name)) AS name_key,
        COUNT(*) OVER (PARTITION BY rc.ca_city, rc.ca_state) AS city_state_count,
        rc.customer_rank
    FROM 
        RankedCustomers rc
)
SELECT 
    pc.full_name,
    pc.ca_city,
    pc.ca_state,
    pc.city_state_count,
    LENGTH(pc.name_key) AS name_length,
    CASE 
        WHEN POSITION('a' IN pc.name_key) > 0 THEN 'Contains A'
        ELSE 'Does Not Contain A'
    END AS contains_a
FROM 
    ProcessedCustomers pc
WHERE 
    pc.customer_rank <= 10
ORDER BY 
    pc.ca_state, pc.ca_city, pc.name_key;
