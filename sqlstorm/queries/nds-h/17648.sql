SELECT l_shipmode, COUNT(*) AS shipment_count
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_shipmode
ORDER BY shipment_count DESC;