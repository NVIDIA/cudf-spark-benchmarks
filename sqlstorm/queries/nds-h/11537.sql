SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY revenue DESC
LIMIT 10;
