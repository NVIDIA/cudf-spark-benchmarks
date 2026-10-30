SELECT p_brand, COUNT(DISTINCT ps_suppkey) AS supplier_count
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_brand
ORDER BY supplier_count DESC
LIMIT 10;
