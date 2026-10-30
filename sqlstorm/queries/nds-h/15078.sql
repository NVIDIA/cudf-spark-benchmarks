SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM lineitem l
WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-02-01'
GROUP BY l.l_orderkey
ORDER BY revenue DESC
LIMIT 10;