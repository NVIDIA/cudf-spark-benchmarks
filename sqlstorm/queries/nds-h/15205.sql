SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
  AND l_shipdate < '1998-01-01'
GROUP BY l_orderkey
ORDER BY revenue DESC
LIMIT 10;