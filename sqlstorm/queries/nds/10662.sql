
SELECT c.c_customer_id, COUNT(sr.sr_ticket_number) AS return_count, SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
FROM customer c
JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2023
GROUP BY c.c_customer_id
ORDER BY total_return_amt DESC
LIMIT 10;
