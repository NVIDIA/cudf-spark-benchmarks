SELECT 
    p.p_brand,
    p.p_container,
    SUM(ps.ps_availqty) AS total_availqty,
    SUM(ps.ps_supplycost) AS total_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
GROUP BY 
    p.p_brand, p.p_container
ORDER BY 
    total_availqty DESC, total_supplycost DESC
LIMIT 100;
