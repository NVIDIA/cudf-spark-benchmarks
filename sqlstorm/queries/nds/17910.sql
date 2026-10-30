
SELECT c_first_name, c_last_name, ca_city, ca_state, cd_gender
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
WHERE cd_gender = 'F'
ORDER BY ca_city, c_last_name;
