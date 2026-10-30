
SELECT c_first_name, c_last_name, ca_city, SUM(ws_net_profit) AS total_profit
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
GROUP BY c_first_name, c_last_name, ca_city
ORDER BY total_profit DESC
LIMIT 10;
