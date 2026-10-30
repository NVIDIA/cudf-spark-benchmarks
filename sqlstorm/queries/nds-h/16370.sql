SELECT l_orderkey, COUNT(*) AS item_count, SUM(l_extendedprice) AS total_price
FROM lineitem
GROUP BY l_orderkey
ORDER BY total_price DESC
LIMIT 10;
