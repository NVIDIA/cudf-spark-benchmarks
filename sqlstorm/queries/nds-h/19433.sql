SELECT s_name, COUNT(*) AS supplier_count
FROM supplier
GROUP BY s_name
HAVING COUNT(*) > 1
ORDER BY supplier_count DESC;
