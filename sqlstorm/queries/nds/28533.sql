
WITH RankedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY LENGTH(ca.ca_street_name) DESC) AS rn
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY')
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_credit_rating,
        a.ca_street_name,
        a.rn  -- Include rn in the select to use in the outer query
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        RankedAddresses a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        (d.cd_gender = 'M' AND d.cd_marital_status = 'S') 
        OR (d.cd_gender = 'F' AND d.cd_marital_status = 'M')
)

SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_credit_rating,
    f.ca_street_name
FROM 
    FilteredCustomers f
WHERE 
    f.rn = 1
ORDER BY 
    f.c_last_name, f.c_first_name;
