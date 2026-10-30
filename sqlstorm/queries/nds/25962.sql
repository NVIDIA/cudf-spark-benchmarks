
WITH Address_City AS (
    SELECT 
        ca_address_sk,
        ca_city,
        LENGTH(ca_street_name) AS street_name_length,
        INITCAP(ca_street_name) AS formatted_street_name
    FROM 
        customer_address
),
Max_Street_Length AS (
    SELECT 
        MAX(street_name_length) AS max_length 
    FROM 
        Address_City
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ac.ca_city,
        ac.formatted_street_name,
        'Name: ' || c.c_first_name || ' ' || c.c_last_name AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_last_name 
            ELSE 'Ms. ' || c.c_last_name 
        END AS title_name
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        Address_City ac ON c.c_current_addr_sk = ac.ca_address_sk
)
SELECT 
    cs.c_customer_sk,
    cs.full_name,
    cs.title_name,
    cs.ca_city,
    cs.formatted_street_name,
    CASE 
        WHEN LENGTH(cs.full_name) > (SELECT max_length FROM Max_Street_Length) THEN 'Exceeds Max Length'
        ELSE 'Within Length'
    END AS name_length_status
FROM 
    Customer_Summary cs
WHERE 
    cs.ca_city IS NOT NULL
GROUP BY 
    cs.c_customer_sk, 
    cs.full_name, 
    cs.title_name, 
    cs.ca_city, 
    cs.formatted_street_name
ORDER BY 
    cs.ca_city, cs.c_customer_sk;
