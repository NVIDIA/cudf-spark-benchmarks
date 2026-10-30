SELECT l_orderkey, SUM(l_quantity) AS total_quantity
FROM lineitem
GROUP BY l_orderkey
ORDER BY total_quantity DESC
LIMIT 10;
