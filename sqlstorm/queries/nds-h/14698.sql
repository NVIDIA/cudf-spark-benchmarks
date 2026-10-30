SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
