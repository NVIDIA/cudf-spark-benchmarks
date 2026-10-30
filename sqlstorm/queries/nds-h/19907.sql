SELECT l_orderkey, COUNT(*) AS line_count, SUM(l_extendedprice) AS total_revenue
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_orderkey
ORDER BY total_revenue DESC
LIMIT 10;