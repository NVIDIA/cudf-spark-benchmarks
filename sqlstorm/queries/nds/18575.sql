
SELECT c_first_name, c_last_name, ca_city, ca_state, COUNT(*) AS purchase_count
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
GROUP BY c_first_name, c_last_name, ca_city, ca_state
ORDER BY purchase_count DESC
LIMIT 10;
