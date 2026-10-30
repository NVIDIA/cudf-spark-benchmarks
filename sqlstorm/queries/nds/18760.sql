
SELECT c_customer_id, COUNT(ss_ticket_number) AS total_sales
FROM customer
JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
GROUP BY c_customer_id
ORDER BY total_sales DESC
LIMIT 10;
