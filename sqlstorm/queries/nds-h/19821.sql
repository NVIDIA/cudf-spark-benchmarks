SELECT n_name, COUNT(DISTINCT c_custkey) AS customer_count
FROM nation
JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
JOIN customer ON supplier.s_suppkey = customer.c_nationkey
GROUP BY n_name
ORDER BY customer_count DESC;
