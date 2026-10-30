SELECT r_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN customer ON orders.o_custkey = customer.c_custkey
JOIN supplier ON lineitem.l_suppkey = supplier.s_suppkey
JOIN nation ON supplier.s_nationkey = nation.n_nationkey
JOIN region ON nation.n_regionkey = region.r_regionkey
WHERE o_orderdate >= '1997-01-01' AND o_orderdate < '1997-12-31'
GROUP BY r_name
ORDER BY revenue DESC;