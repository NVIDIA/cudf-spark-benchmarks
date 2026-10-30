SELECT 
    p.p_type, 
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(l.l_quantity) AS avg_quantity, 
    MAX(l.l_tax) AS max_tax
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND c.c_mktsegment = 'BUILDING' 
    AND l.l_shipmode IN ('AIR', 'GROUND')
GROUP BY 
    p.p_type
ORDER BY 
    total_revenue DESC, 
    num_suppliers DESC 
LIMIT 10;
