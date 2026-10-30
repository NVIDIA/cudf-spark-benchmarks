
SELECT count(*) AS total_customers, 
       cd_gender, 
       ca_state 
FROM customer 
JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
JOIN customer_address ON c_current_addr_sk = ca_address_sk 
WHERE cd_marital_status = 'M' 
GROUP BY cd_gender, ca_state 
ORDER BY total_customers DESC;
