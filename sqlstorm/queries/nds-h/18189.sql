SELECT s_name, COUNT(*) AS supplier_count
FROM supplier
JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
GROUP BY s_name
ORDER BY supplier_count DESC
LIMIT 10;
