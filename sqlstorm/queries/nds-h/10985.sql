SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_avail_qty DESC
LIMIT 10;
