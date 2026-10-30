SELECT l_orderkey, COUNT(*) AS line_item_count 
FROM lineitem 
GROUP BY l_orderkey 
ORDER BY line_item_count DESC 
LIMIT 10;
