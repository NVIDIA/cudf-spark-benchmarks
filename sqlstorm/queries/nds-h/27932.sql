SELECT DISTINCT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    r.r_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%ASIA%' 
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_sales DESC;