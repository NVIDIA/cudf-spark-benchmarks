SELECT l_shipmode, COUNT(*) AS shipping_counts
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_shipmode
ORDER BY shipping_counts DESC;