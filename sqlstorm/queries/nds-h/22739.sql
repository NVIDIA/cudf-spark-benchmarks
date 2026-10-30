
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(sh.full_name, ' -> ', s.s_name) AS full_name,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey <> sh.s_suppkey
    WHERE sh.level < 3
)

SELECT r.r_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       AVG(ps.ps_supplycost) AS avg_supplycost,
       SUM(CASE WHEN l.l_shipdate IS NULL THEN 1 ELSE 0 END) AS null_shipdate_count,
       STRING_AGG(DISTINCT CONCAT(p.p_name, '(', p.p_size, ')'), ', ') AS part_details
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE r.r_name IS NOT NULL
  AND (c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
       OR c.c_comment IS NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_customers DESC, r.r_name
LIMIT 5 OFFSET 10;
