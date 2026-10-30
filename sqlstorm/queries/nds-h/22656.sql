WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000

    UNION ALL

    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        sh.level < 5
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT n.n_nationkey) AS num_nations,
    SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS total_acct_bal, 
    MAX(COALESCE(l.l_discount / NULLIF(l.l_extendedprice, 0), 0)) AS max_discount_ratio,
    STRING_AGG(DISTINCT CASE WHEN p.p_size IS NOT NULL THEN p.p_name || ' - ' || p.p_type ELSE 'Unknown Part' END, ', ') AS part_details
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey AND l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1 AND SUM(s.s_acctbal) > 5000
ORDER BY 
    total_acct_bal DESC
LIMIT 5 OFFSET 10;