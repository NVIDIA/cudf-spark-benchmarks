SELECT l_partkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY l_partkey
ORDER BY revenue DESC
LIMIT 10;