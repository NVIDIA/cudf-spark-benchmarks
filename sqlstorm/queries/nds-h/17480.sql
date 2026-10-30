SELECT l_shipmode, SUM(l_extendedprice) AS total_revenue
FROM lineitem
WHERE l_shipdate >= '1996-01-01' AND l_shipdate < '1996-12-31'
GROUP BY l_shipmode
ORDER BY total_revenue DESC;