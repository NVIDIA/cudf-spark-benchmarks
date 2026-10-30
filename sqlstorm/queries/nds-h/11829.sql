SELECT 
    p.p_partkey, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
    AND l.l_shipdate > '1997-01-01'
GROUP BY 
    p.p_partkey
ORDER BY 
    total_revenue DESC
LIMIT 10;