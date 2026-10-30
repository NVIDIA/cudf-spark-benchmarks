SELECT l_partkey, SUM(l_quantity) AS total_quantity
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY l_partkey
ORDER BY total_quantity DESC
LIMIT 10;