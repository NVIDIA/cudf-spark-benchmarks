
SELECT 
    LEFT(ca_city, 4) AS city_prefix,
    LENGTH(ca_street_name) AS street_name_length,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state = 'CA'
    AND cd_marital_status = 'M'
    AND ca_city IS NOT NULL
GROUP BY 
    LEFT(ca_city, 4),
    LENGTH(ca_street_name)
ORDER BY 
    city_prefix, street_name_length DESC
LIMIT 100;
