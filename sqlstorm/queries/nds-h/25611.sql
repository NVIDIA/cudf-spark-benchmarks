SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING(p.p_comment, 1, 10) || '...' AS short_comment,
    s.s_name AS supplier_name,
    n.n_name AS nation_name
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    p.p_type LIKE '%BRASS%' 
    AND l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31' 
GROUP BY 
    p.p_name, s.s_name, n.n_name, p.p_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
ORDER BY 
    revenue DESC 
LIMIT 10;