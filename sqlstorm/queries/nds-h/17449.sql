SELECT n_name, SUM(o_totalprice) AS total_revenue
FROM nation
JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
JOIN customer ON supplier.s_suppkey = customer.c_custkey
JOIN orders ON customer.c_custkey = orders.o_custkey
GROUP BY n_name
ORDER BY total_revenue DESC;
