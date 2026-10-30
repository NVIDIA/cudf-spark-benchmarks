
SELECT c.c_customer_id, ca.ca_city, SUM(ss.ss_sales_price) AS total_sales
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY c.c_customer_id, ca.ca_city
ORDER BY total_sales DESC
LIMIT 10;
