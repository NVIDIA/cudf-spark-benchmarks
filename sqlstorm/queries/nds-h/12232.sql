SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
