SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
GROUP BY n_name
ORDER BY total_revenue DESC;
