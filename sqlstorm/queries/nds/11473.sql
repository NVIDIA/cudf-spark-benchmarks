
SELECT c.c_customer_id, COUNT(sr.sr_ticket_number) AS total_returns, SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
FROM customer c
JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY c.c_customer_id
ORDER BY total_return_amount DESC
LIMIT 100;
