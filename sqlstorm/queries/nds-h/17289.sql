SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN lineitem ON partsupp.ps_suppkey = lineitem.l_suppkey
WHERE l_shipdate >= '1996-01-01' AND l_shipdate < '1997-01-01'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;