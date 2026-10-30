SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    RANK() OVER (PARTITION BY p.p_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
WHERE 
    LENGTH(s.s_name) > 10 
    AND p.p_retailprice BETWEEN 10.00 AND 100.00 
    AND o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-10-01' 
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_revenue DESC, 
    p.p_name, 
    s.s_name;