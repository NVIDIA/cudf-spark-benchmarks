SELECT p_name, SUM(l_quantity) AS total_quantity
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN lineitem ON partsupp.ps_partkey = lineitem.l_partkey
GROUP BY p_name
ORDER BY total_quantity DESC
LIMIT 10;
