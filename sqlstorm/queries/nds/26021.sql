
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    (CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single' 
     END) AS marital_status,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    UPPER(c.c_email_address) AS upper_email,
    LENGTH(ca.ca_street_name) AS street_name_length,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_city = ca.ca_city AND s.s_state = ca.ca_state) AS store_count,
    INITCAP(ca.ca_street_name) AS formatted_street_name,
    CONCAT_WS(', ', ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND ca.ca_state IN ('CA', 'NY')
    AND LENGTH(ca.ca_city) > 5
ORDER BY 
    ca.ca_city, 
    c.c_last_name, 
    c.c_first_name
LIMIT 100;
