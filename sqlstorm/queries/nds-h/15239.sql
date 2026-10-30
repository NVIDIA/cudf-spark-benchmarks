SELECT l_orderkey, COUNT(*) AS lineitem_count, SUM(l_extendedprice) AS total_extended_price
FROM lineitem
GROUP BY l_orderkey
ORDER BY total_extended_price DESC
LIMIT 10;
