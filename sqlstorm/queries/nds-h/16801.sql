SELECT p_brand, COUNT(*) AS supplier_count
FROM partsupp ps
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY p_brand
ORDER BY supplier_count DESC
LIMIT 10;
