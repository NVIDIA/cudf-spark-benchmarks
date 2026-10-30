
SELECT c_first_name, c_last_name, COUNT(ss_ticket_number) AS total_purchases
FROM customer
JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
GROUP BY c_first_name, c_last_name
ORDER BY total_purchases DESC
LIMIT 10;
