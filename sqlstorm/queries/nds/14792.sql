
SELECT ca_city, COUNT(DISTINCT c_customer_id) AS customer_count
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE dd.d_year = 2022
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
