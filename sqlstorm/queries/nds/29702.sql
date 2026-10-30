
SELECT 
    ca_address_id,
    CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
    cd_gender,
    cd_marital_status,
    REPLACE(cd_education_status, ' ', '_') AS education_status_formatted,
    SUBSTRING(cd_credit_rating, 1, 3) AS short_credit_rating,
    COUNT(DISTINCT c_customer_id) AS customer_count
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city LIKE '%Springfield%' 
    AND cd_gender = 'F' 
    AND cd_marital_status = 'M'
GROUP BY 
    ca_address_id, 
    ca_street_number, 
    ca_street_name, 
    ca_street_type, 
    ca_suite_number, 
    ca_city, 
    ca_state, 
    ca_zip, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    cd_credit_rating
ORDER BY 
    customer_count DESC;
