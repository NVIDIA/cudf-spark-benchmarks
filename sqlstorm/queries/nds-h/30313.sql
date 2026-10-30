WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000
)

SELECT 
    p.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_value,
    AVG(l.l_quantity) AS avg_quantity,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS rn
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    supplier s2 ON s.s_nationkey = s2.s_nationkey AND s2.s_acctbal IS NOT NULL
JOIN 
    region r ON s2.s_nationkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND (s.s_comment IS NULL OR s.s_comment LIKE '%important%')
    AND (p.p_retailprice BETWEEN 10 AND 100) 
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_returned_value DESC, avg_quantity ASC
LIMIT 10;