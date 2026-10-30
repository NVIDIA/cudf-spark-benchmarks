SELECT n_name, COUNT(DISTINCT s_suppkey) AS supplier_count
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY n_name
ORDER BY supplier_count DESC;
