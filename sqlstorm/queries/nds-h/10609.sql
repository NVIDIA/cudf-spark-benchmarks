SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'REGION_NAME'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_sales DESC
LIMIT 10;
