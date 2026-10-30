SELECT n_name, COUNT(DISTINCT s_suppkey) AS supplier_count
FROM nation
JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
GROUP BY n_name
ORDER BY supplier_count DESC;
