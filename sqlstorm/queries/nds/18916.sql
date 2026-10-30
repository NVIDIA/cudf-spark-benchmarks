
SELECT c.c_customer_id, COUNT(sr_ticket_number) AS returns_count
FROM customer c
JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY c.c_customer_id
ORDER BY returns_count DESC
LIMIT 10;
