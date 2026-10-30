
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)

SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_quantity) AS avg_quantity,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS suppliers,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN o.o_orderkey END) AS returns_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_retailprice IS NOT NULL
  AND (s.s_acctbal > 0 OR s.s_comment LIKE '%high%')
  AND (o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' OR o.o_orderstatus = 'F')
GROUP BY p.p_partkey, p.p_name
HAVING COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 10000
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 10;
