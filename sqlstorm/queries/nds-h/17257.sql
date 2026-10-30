SELECT l_partkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1997-02-01'
GROUP BY l_partkey
ORDER BY total_revenue DESC
LIMIT 10;