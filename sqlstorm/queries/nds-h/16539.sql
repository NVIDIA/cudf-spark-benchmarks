SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY l_orderkey
ORDER BY revenue DESC
LIMIT 10;