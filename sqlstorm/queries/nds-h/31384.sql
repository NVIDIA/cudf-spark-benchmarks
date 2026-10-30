WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal
)

SELECT
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE
        WHEN SUM(l.l_extendedprice) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Available'
    END AS revenue_status
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE o.o_orderstatus = 'F'
    AND (l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31')
    AND s.s_acctbal IS NOT NULL
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY revenue DESC
LIMIT 10;