SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-02-01'
GROUP BY p.p_name
ORDER BY revenue DESC
LIMIT 10;