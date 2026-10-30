SELECT p.p_name, SUM(lineitem.l_quantity) AS total_quantity
FROM part p
JOIN lineitem ON p.p_partkey = lineitem.l_partkey
GROUP BY p.p_name
ORDER BY total_quantity DESC
LIMIT 10;
