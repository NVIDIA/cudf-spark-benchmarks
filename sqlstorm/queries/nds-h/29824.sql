
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Total Revenue: ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS VARCHAR(255)), ' | Supplier Count: ', CAST(COUNT(DISTINCT ps.ps_suppkey) AS VARCHAR(255))) AS revenue_supplier_info,
    r.r_name,
    n.n_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%BRASS%'
GROUP BY 
    p.p_name, r.r_name, n.n_name, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 20;
