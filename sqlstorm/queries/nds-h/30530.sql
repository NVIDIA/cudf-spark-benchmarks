WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        1 AS hierarchy_level
    FROM
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000  
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        sh.hierarchy_level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey  
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(s.s_acctbal) AS average_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_sales DESC
LIMIT 10;