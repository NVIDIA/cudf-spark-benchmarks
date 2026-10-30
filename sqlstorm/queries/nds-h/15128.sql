SELECT p_name, SUM(ps_supplycost * ps_availqty) AS total_cost
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY p_name
ORDER BY total_cost DESC
LIMIT 10;
