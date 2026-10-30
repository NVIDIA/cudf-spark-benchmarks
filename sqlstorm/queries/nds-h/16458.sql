SELECT l_orderkey, COUNT(*) AS line_count
FROM lineitem
GROUP BY l_orderkey
HAVING COUNT(*) > 1
ORDER BY line_count DESC;
