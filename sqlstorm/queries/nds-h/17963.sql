SELECT p_brand, COUNT(*) AS supply_count 
FROM part 
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey 
GROUP BY p_brand 
ORDER BY supply_count DESC;
