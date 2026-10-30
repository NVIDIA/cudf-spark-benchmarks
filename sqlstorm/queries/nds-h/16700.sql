SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN customer c ON c.c_custkey = l.l_orderkey
WHERE c.c_mktsegment = 'BUILDING'
GROUP BY p.p_name
ORDER BY revenue DESC
LIMIT 10;
