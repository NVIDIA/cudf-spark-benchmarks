SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM lineitem
JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN customer ON orders.o_custkey = customer.c_custkey
JOIN nation ON customer.c_nationkey = nation.n_nationkey
WHERE l_shipdate >= DATE '1997-01-01'
GROUP BY n_name
ORDER BY total_revenue DESC;