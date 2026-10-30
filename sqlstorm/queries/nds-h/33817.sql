
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           CAST(s.s_name AS STRING) AS path, 
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           CONCAT(sh.path, ' > ', s.s_name), 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(CASE WHEN p.p_size >= 10 THEN ps.ps_availqty ELSE 0 END) AS total_availqty,
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY AVG(l.l_extendedprice) DESC) AS region_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
WHERE l.l_returnflag = 'N'
  AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY r.r_name, 
         r.r_regionkey
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY region_rank
LIMIT 10;
