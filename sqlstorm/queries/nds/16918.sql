
SELECT c_first_name, c_last_name, ca_city, SUM(ss_sales_price) AS total_sales
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
GROUP BY c_first_name, c_last_name, ca_city
ORDER BY total_sales DESC
LIMIT 10;
