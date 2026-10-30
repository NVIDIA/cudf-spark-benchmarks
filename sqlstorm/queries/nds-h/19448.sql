SELECT l_shipmode, COUNT(*) AS ship_count
FROM lineitem
WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY l_shipmode
ORDER BY ship_count DESC;