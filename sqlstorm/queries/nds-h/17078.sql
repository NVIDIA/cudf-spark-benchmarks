SELECT n_name, COUNT(DISTINCT s_suppkey) AS supplier_count
FROM nation AS n
JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
GROUP BY n.n_name
ORDER BY supplier_count DESC;
