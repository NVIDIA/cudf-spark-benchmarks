SELECT p.p_name, COUNT(ps.ps_suppkey) AS supplier_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY p.p_name
ORDER BY supplier_count DESC
LIMIT 10;
