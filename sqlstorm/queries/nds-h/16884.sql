SELECT p_brand, COUNT(*) AS supplier_count 
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY p_brand
ORDER BY supplier_count DESC;
