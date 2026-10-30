SELECT p_name, SUM(l_quantity) as total_quantity
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
GROUP BY p_name
ORDER BY total_quantity DESC
LIMIT 10;
