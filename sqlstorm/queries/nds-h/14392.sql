SELECT 
    p.p_brand, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
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
    r.r_name = 'ASIA' 
    AND l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1997-12-31'
GROUP BY 
    p.p_brand
ORDER BY 
    avg_price DESC;