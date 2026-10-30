SELECT l_shipmode, COUNT(*) AS number_of_orders
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_shipmode
ORDER BY number_of_orders DESC;