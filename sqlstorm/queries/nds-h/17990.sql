SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
JOIN partsupp ON lineitem.l_partkey = partsupp.ps_partkey
JOIN part ON partsupp.ps_partkey = part.p_partkey
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;
