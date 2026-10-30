
SELECT c_first_name, c_last_name, ca_city, s_store_name, ss_sales_price 
FROM customer 
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk 
JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk 
JOIN store ON store_sales.ss_store_sk = store.s_store_sk 
WHERE ca_city = 'San Francisco' AND ss_sales_price > 100 
ORDER BY ss_sales_price DESC;
