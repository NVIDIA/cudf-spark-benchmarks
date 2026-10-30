
SELECT ca_state, COUNT(*) AS customer_count
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
GROUP BY ca_state
ORDER BY customer_count DESC
LIMIT 10;
