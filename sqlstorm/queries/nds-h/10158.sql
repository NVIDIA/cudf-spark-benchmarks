SELECT l_shipmode, COUNT(DISTINCT o_orderkey) AS total_orders, SUM(l_extendedprice) AS total_revenue
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY l_shipmode
ORDER BY total_revenue DESC;