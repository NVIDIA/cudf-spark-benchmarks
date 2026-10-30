SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
GROUP BY n_name
ORDER BY total_revenue DESC;
