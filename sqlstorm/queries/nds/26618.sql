
SELECT 
    ca_state,
    CONCAT(ca_city, ', ', ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(CASE 
            WHEN cd_gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_customers,
    SUM(CASE 
            WHEN cd_gender = 'M' THEN 1 
            ELSE 0 
        END) AS male_customers,
    COUNT(CASE 
            WHEN cd_marital_status = 'M' THEN 1 
            END) AS married_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT c_login) AS unique_logins
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX')
GROUP BY 
    ca_state, full_address
ORDER BY 
    ca_state, customer_count DESC
LIMIT 100;
