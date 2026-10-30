
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           CAST(s.s_name AS STRING) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal <> sh.s_acctbal
)

SELECT n.n_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
       SUM(CASE WHEN ps.ps_supplycost > 1000 THEN ps.ps_availqty ELSE 0 END) AS expensive_supply_qty,
       AVG(CASE 
               WHEN l.l_discount IS NULL THEN 0 
               ELSE l.l_extendedprice * (1 - l.l_discount)
           END) AS avg_discounted_price,
       STRING_AGG(DISTINCT p.p_name, '; ') AS part_names,
       ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT l.l_orderkey) DESC) AS order_rank
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE s.s_acctbal BETWEEN 100 AND 500
  AND l.l_shipdate BETWEEN DATE '1994-01-01' AND DATE '1997-12-31'
  AND (s.s_comment LIKE '%important%' OR s.s_comment IS NULL)
GROUP BY n.n_name, n.n_nationkey
HAVING COUNT(DISTINCT s.s_suppkey) > 3
   AND SUM(COALESCE(ps.ps_supplycost, 0)) > 5000
ORDER BY order_rank DESC
LIMIT 10;
