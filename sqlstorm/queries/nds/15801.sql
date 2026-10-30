
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
WHERE 
    cd.cd_gender = 'F' 
    AND ca.ca_state = 'CA';
