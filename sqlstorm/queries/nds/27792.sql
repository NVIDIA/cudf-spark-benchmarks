
SELECT 
    CONCAT_WS(', ', 
        ca_street_number, 
        ca_street_name, 
        ca_street_type, 
        COALESCE(ca_suite_number, ''), 
        ca_city, 
        ca_county, 
        ca_state, 
        ca_zip, 
        ca_country) AS full_address,
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'NY') 
    AND cd_purchase_estimate > 1000
GROUP BY 
    ca_street_number, 
    ca_street_name, 
    ca_street_type, 
    ca_suite_number, 
    ca_city, 
    ca_county, 
    ca_state, 
    ca_zip, 
    ca_country, 
    cd_gender, 
    cd_marital_status
ORDER BY 
    customer_count DESC;
