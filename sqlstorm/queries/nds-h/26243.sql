
SELECT 
    p.p_name, 
    s.s_name, 
    SUBSTRING(s.s_comment, 1, 50) AS short_comment, 
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%excellent%' 
    AND o.o_orderdate >= '1997-01-01' 
GROUP BY 
    p.p_name, 
    s.s_name, 
    short_comment, 
    n.n_name, 
    r.r_name
ORDER BY 
    total_revenue DESC 
LIMIT 10;
