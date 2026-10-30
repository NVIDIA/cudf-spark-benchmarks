SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name = 'ASIA' AND o.o_orderdate >= DATE '1997-01-01'
GROUP BY p.p_name
ORDER BY total_revenue DESC
LIMIT 10;