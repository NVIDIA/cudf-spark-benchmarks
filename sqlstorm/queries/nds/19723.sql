
SELECT c_first_name, c_last_name, ca_city, COUNT(ss_ticket_number) AS total_sales
FROM customer
JOIN customer_address ON c_current_addr_sk = ca_address_sk
JOIN store_sales ON c_customer_sk = ss_customer_sk
GROUP BY c_first_name, c_last_name, ca_city
ORDER BY total_sales DESC
LIMIT 10;
