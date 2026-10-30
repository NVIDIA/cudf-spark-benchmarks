SELECT 
    s.s_name,
    n.n_name,
    r.r_name,
    p.p_name,
    SUM(ps.ps_availqty) AS total_availqty,
    SUM(ps.ps_supplycost) AS total_supplycost
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_name
ORDER BY 
    total_availqty DESC
LIMIT 100;
