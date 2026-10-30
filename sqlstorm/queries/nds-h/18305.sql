SELECT p_name, SUM(l_quantity) AS total_quantity
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN lineitem ON supplier.s_suppkey = lineitem.l_suppkey
GROUP BY p_name
ORDER BY total_quantity DESC
LIMIT 10;
