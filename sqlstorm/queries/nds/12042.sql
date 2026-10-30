
SELECT c.c_customer_id, 
       COUNT(DISTINCT s.ss_ticket_number) AS total_sales, 
       SUM(s.ss_sales_price) AS total_amount_spent
FROM customer c
JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
WHERE c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY c.c_customer_id
ORDER BY total_amount_spent DESC
LIMIT 10;
