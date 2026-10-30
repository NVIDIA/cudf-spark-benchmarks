SELECT p_brand, COUNT(*) as supplier_count
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
GROUP BY p_brand
ORDER BY supplier_count DESC
LIMIT 10;
