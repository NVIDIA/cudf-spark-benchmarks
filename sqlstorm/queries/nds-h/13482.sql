SELECT 
    n.n_name AS nation, 
    r.r_name AS region, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_availability, 
    AVG(ps.ps_supplycost) AS average_supply_cost
FROM 
    supplier s 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
GROUP BY 
    n.n_name, 
    r.r_name 
ORDER BY 
    region, 
    nation;
