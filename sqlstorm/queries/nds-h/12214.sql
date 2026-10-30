SELECT 
    n_name, 
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
