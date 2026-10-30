
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        CAST(s.s_name AS VARCHAR(100)) AS full_name,
        0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.s_nationkey,
        sp.s_acctbal,
        CONCAT(sh.full_name, ' -> ', sp.s_name) AS full_name,
        sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > 500
)

SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE o.o_orderdate >= '1997-01-01'
AND l.l_shipdate <= '1997-12-31'
AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY r.r_name, n.n_name
HAVING SUM(l.l_extendedprice) > 10000 
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 5;
