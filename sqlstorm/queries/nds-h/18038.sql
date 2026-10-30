SELECT p.p_name, SUM(l.l_quantity) AS total_quantity
FROM part AS p
JOIN lineitem AS l ON p.p_partkey = l.l_partkey
GROUP BY p.p_name
ORDER BY total_quantity DESC
LIMIT 10;
