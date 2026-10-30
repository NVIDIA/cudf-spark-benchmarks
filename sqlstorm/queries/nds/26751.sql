
WITH AddressCount AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
TopStates AS (
    SELECT 
        ca_state
    FROM 
        AddressCount
    WHERE 
        address_count > (SELECT AVG(address_count) FROM AddressCount)
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN (SELECT ca_state FROM TopStates)
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name || ' ' || ci.c_last_name AS full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    CustomerInfo AS ci
WHERE 
    ci.cd_gender = 'M' 
    AND ci.cd_marital_status = 'S'
ORDER BY 
    ci.ca_state, ci.c_last_name, ci.c_first_name;
