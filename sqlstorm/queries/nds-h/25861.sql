SELECT p.p_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
       SUM(ps.ps_availqty) AS total_available, 
       AVG(p.p_retailprice) AS avg_price,
       CONCAT('Part: ', p.p_name, ' | Suppliers: ', COUNT(DISTINCT s.s_suppkey), 
              ' | Total Available: ', SUM(ps.ps_availqty), 
              ' | Average Price: ', ROUND(AVG(p.p_retailprice), 2)) AS description
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size BETWEEN 1 AND 50
AND p.p_mfgr LIKE 'Manufacturer%'
AND r.r_name IN (SELECT DISTINCT r_name FROM region WHERE r_comment LIKE '%special%')
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_available DESC, avg_price ASC;
