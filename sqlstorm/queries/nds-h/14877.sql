SELECT 
    n.n_name AS nation_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost 
FROM 
    nation n 
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
GROUP BY 
    n.n_name 
ORDER BY 
    total_supply_cost DESC 
LIMIT 10;
