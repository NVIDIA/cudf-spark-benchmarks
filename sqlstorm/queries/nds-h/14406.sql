SELECT 
    p.p_brand, 
    p.p_type, 
    AVG(ps.ps_supplycost) AS avg_supplycost, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'Europe'
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    avg_supplycost DESC, total_revenue DESC;