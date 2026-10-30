SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM customer AS c
JOIN orders AS o ON c.c_custkey = o.o_custkey
JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN partsupp AS ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN part AS p ON ps.ps_partkey = p.p_partkey
JOIN nation AS n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY revenue DESC
LIMIT 10;
