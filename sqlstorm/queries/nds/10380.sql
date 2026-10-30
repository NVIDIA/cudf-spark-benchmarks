
SELECT ca_address_id, ca_city, ca_state, COUNT(*) AS customer_count
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
GROUP BY ca_address_id, ca_city, ca_state
ORDER BY customer_count DESC
LIMIT 100;
