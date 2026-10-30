
SELECT c.c_first_name, c.c_last_name, sa.ca_city, sa.ca_state, COUNT(ss.ss_ticket_number) AS total_sales
FROM customer c
JOIN customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c.c_first_name, c.c_last_name, sa.ca_city, sa.ca_state
ORDER BY total_sales DESC
LIMIT 10;
