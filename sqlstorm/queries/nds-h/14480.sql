SELECT l_shipmode, COUNT(*) AS shipping_count, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM lineitem
WHERE l_shipdate BETWEEN '1994-01-01' AND '1995-01-01'
GROUP BY l_shipmode
ORDER BY shipping_count DESC, total_revenue DESC;
