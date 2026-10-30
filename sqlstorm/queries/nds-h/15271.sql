SELECT c.c_name, SUM(o.o_totalprice) AS total_spent
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
GROUP BY c.c_name
ORDER BY total_spent DESC
LIMIT 10;
