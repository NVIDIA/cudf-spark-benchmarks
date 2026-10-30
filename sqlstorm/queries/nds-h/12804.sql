SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    s.s_suppkey,
    s.s_name,
    SUM(ps.ps_availqty) AS total_availqty,
    SUM(ps.ps_supplycost) AS total_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_suppkey, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supplycost DESC
LIMIT 50;
