SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT(n.n_name, ' - ', r.r_name) AS nation_region
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
WHERE 
    p.p_comment LIKE '%supply%' 
    AND s.s_comment NOT LIKE '%special%' 
GROUP BY 
    s.s_name, p.p_name, n.n_name, r.r_name 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    average_supply_cost DESC, total_available_quantity DESC 
LIMIT 10;
