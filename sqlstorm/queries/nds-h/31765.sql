WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) DESC) AS revenue_rank,
    r.r_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (l.l_shipdate > '1997-01-01' OR l.l_shipdate IS NULL)
    AND (n.n_name LIKE '%USA%' OR n.n_comment IS NOT NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name
HAVING 
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) > 5000
ORDER BY 
    revenue_rank,
    total_revenue DESC
LIMIT 10