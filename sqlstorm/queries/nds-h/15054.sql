SELECT n_name, COUNT(DISTINCT s_suppkey) AS supplier_count
FROM nation
JOIN supplier ON n_nationkey = s_nationkey
GROUP BY n_name
ORDER BY supplier_count DESC;
