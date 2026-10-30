
SELECT c.c_first_name, c.c_last_name, ca.ca_city, sd.ss_sales_price 
FROM customer c 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN store_sales sd ON c.c_customer_sk = sd.ss_customer_sk 
WHERE ca.ca_state = 'NY' 
ORDER BY sd.ss_sales_price DESC 
LIMIT 10;
