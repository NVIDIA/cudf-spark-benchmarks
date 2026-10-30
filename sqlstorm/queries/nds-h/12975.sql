SELECT 
    p.p_brand,
    p.p_type,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON ls.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-02-01'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    total_revenue DESC;