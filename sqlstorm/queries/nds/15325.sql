
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, cd.cd_gender
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
ORDER BY ca.ca_city;
