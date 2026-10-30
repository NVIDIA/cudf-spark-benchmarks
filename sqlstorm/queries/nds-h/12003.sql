SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_supply_cost DESC
LIMIT 100;
