SELECT l_shipmode, COUNT(*) AS shipping_count
FROM lineitem
WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY l_shipmode
ORDER BY shipping_count DESC;