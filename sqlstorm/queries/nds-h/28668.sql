
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(l.l_quantity) AS avg_quantity 
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
    p.p_type LIKE '%brass%' 
    AND r.r_name IN ('AMERICA', 'EUROPE') 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name 
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
ORDER BY 
    total_revenue DESC, avg_quantity ASC 
LIMIT 100;
