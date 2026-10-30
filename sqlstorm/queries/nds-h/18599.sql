SELECT r_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM nation
JOIN region ON nation.n_regionkey = region.r_regionkey
JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN part ON partsupp.ps_partkey = part.p_partkey
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE o_orderdate BETWEEN '1997-01-01' AND '1997-01-31'
GROUP BY r_name
ORDER BY revenue DESC;