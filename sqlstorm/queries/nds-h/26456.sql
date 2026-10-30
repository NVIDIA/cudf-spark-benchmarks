SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    r.r_name AS region_name, 
    CASE 
        WHEN LENGTH(s.s_name) > 10 THEN SUBSTRING(s.s_name FROM 1 FOR 10) || '...' 
        ELSE s.s_name 
    END AS supplier_name, 
    CONCAT('Total Revenue for ', s.s_name, ' in ', r.r_name) AS revenue_description 
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
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    l.l_returnflag = 'N' 
GROUP BY 
    p.p_name, s.s_name, r.r_name 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
ORDER BY 
    total_revenue DESC;