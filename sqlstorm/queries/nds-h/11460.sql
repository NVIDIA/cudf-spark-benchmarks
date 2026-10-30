SELECT 
    p.p_brand, 
    p.p_type, 
    SUM(ls.l_quantity) AS total_quantity, 
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_price
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    supplier s ON ls.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_brand, 
    p.p_type
ORDER BY 
    total_quantity DESC, 
    total_price DESC
LIMIT 10;
