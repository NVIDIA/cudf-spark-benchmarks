SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN lineitem ON supplier.s_suppkey = lineitem.l_suppkey
WHERE lineitem.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;