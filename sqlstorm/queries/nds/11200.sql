
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers, 
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers, 
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers 
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim AS d ON d.d_date_sk = c.c_first_sales_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC;
