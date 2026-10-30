SELECT c_name, SUM(o_totalprice) AS total_spent
FROM customer
JOIN orders ON customer.c_custkey = orders.o_custkey
GROUP BY c_name
ORDER BY total_spent DESC
LIMIT 10;
