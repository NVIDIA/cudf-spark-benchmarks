SELECT l_shipmode, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_shipmode
ORDER BY total_revenue DESC;