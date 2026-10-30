SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_availqty) AS total_availqty, 
    SUM(ps.ps_supplycost) AS total_supplycost
FROM 
    part p
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
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type
ORDER BY 
    total_availqty DESC
LIMIT 10;
