
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT n.r_name, p.p_type, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_acctbal,
       ROW_NUMBER() OVER (PARTITION BY n.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
FROM region n
LEFT JOIN nation ON n.r_regionkey = nation.n_regionkey
LEFT JOIN supplier s ON nation.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE (p.p_size > 10 OR p.p_container IS NULL)
  AND (l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31')
  AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
GROUP BY n.r_name, p.p_type
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) 
                                                       FROM (
                                                           SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
                                                           FROM lineitem l 
                                                           JOIN orders o ON l.l_orderkey = o.o_orderkey 
                                                           GROUP BY o.o_orderkey
                                                       ) AS subquery)
ORDER BY n.r_name, total_revenue DESC
LIMIT 10 OFFSET 0;
