SELECT 
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' AND 
    o.o_orderdate < DATE '1996-01-01' AND 
    p.p_brand = 'Brand#54' AND 
    p.p_type LIKE 'MEDIUM POLISHED%'
GROUP BY 
    n.n_name
ORDER BY 
    revenue DESC;
