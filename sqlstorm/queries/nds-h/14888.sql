SELECT 
    n.n_name,
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_sales DESC;