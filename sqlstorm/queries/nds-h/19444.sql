SELECT p_name, SUM(l_quantity) AS total_quantity
FROM lineitem
JOIN partsupp ON lineitem.l_partkey = partsupp.ps_partkey
JOIN part ON partsupp.ps_partkey = part.p_partkey
GROUP BY p_name
ORDER BY total_quantity DESC
LIMIT 10;
