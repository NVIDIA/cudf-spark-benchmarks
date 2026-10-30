SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM nation
JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN lineitem ON partsupp.ps_partkey = lineitem.l_partkey
GROUP BY n_name
ORDER BY total_revenue DESC;
