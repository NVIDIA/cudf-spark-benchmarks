SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN lineitem ON partsupp.ps_partkey = lineitem.l_partkey
WHERE lineitem.l_shipdate >= DATE '1997-01-01'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;