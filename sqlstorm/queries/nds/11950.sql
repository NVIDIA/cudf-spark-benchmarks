
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(CASE 
            WHEN cd_gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_count,
    SUM(CASE 
            WHEN cd_gender = 'M' THEN 1 
            ELSE 0 
        END) AS male_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
