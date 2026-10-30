SELECT p_brand, COUNT(DISTINCT ps_suppkey) AS supplier_count
FROM part 
JOIN partsupp ON p_partkey = ps_partkey
GROUP BY p_brand
ORDER BY supplier_count DESC;
