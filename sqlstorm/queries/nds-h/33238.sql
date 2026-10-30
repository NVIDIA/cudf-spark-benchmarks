
WITH RECURSIVE SupplyHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level,
        CAST(s.s_name AS VARCHAR(100)) AS path
    FROM 
        supplier s
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        sh.s_name,
        sh.s_acctbal,
        sh.level + 1,
        CAST(sh.path || ' -> ' || s.s_name AS VARCHAR(100))
    FROM 
        partsupp ps
    JOIN 
        SupplyHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER(PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN AVG(s.s_acctbal) IS NULL THEN 'No Suppliers'
        ELSE CAST(AVG(s.s_acctbal) AS STRING)
    END AS average_suppllier_balance
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment = 'FURNITURE')
GROUP BY 
    n.n_nationkey, r.r_regionkey, n.n_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    n.n_name, r.r_name;
