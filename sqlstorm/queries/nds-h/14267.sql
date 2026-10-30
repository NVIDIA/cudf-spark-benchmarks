SELECT 
    p.p_brand,
    p.p_type,
    p.p_size,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS revenue
FROM 
    lineitem ls
JOIN 
    part p ON ls.l_partkey = p.p_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'EUROPE' AND 
    ls.l_shipdate >= DATE '1997-01-01' AND 
    ls.l_shipdate < DATE '1997-12-31'
GROUP BY 
    p.p_brand, p.p_type, p.p_size
ORDER BY 
    revenue DESC;