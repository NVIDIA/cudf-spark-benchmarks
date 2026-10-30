
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(sr.sr_ticket_number) AS total_returns,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_return_quantity) AS total_returned_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
    AND ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_customer_id, full_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
    ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_returns DESC, avg_return_amount DESC
LIMIT 100;
