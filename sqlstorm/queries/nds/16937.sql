
SELECT c_first_name, c_last_name, ca_city, SUM(ws_ext_sales_price) AS total_sales
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY c_first_name, c_last_name, ca_city
ORDER BY total_sales DESC
LIMIT 10;
