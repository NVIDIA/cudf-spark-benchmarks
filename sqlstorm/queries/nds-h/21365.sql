
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           1 AS level,
           CAST(s.s_name AS STRING) AS path
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1,
           CONCAT(sh.path, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)

SELECT
    p.p_name,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    (SELECT COUNT(*)
     FROM customer c
     WHERE c.c_acctbal > 10000 AND c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')) AS high_value_customers,
    CASE WHEN AVG(ps.ps_supplycost) IS NULL THEN 'NO SUPPLIERS' ELSE 'SUPPLIER EXISTS' END AS supplier_status,
    'Total: ' || CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS STRING) AS total_string
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL OR o.o_orderstatus = 'P')
GROUP BY p.p_name, r.r_name
HAVING SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) >= (
          SELECT AVG(total_revenue)
          FROM (
              SELECT SUM(COALESCE(l_extendedprice, 0) * (1 - l_discount)) AS total_revenue
              FROM lineitem
              WHERE l_shipdate >= '1996-01-01'
              GROUP BY l_orderkey
          ) AS subquery
      )
ORDER BY revenue_rank, p.p_name;
