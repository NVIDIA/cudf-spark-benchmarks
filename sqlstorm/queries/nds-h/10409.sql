SELECT l_shipmode, COUNT(*) AS shipment_count, SUM(l_extendedprice) AS total_revenue
FROM lineitem
WHERE l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY l_shipmode
ORDER BY shipment_count DESC;