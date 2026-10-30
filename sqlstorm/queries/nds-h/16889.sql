SELECT l_shipmode, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
WHERE l_shipdate >= '1994-01-01' AND l_shipdate < '1995-01-01'
GROUP BY l_shipmode
ORDER BY revenue DESC;
