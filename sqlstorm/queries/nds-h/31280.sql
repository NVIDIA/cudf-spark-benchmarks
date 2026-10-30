
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000

    UNION ALL

    SELECT s.s_nationkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SalesHierarchy sh ON s.s_nationkey = sh.c_custkey
    WHERE s.s_acctbal < (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    n.n_name AS supplier_nation
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_orderkey = l.l_orderkey
        AND o.o_totalprice > 500
    )
GROUP BY 
    p.p_partkey, p.p_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
    OR SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL
ORDER BY 
    total_revenue DESC
LIMIT 10;
