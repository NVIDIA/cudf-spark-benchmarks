SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    CONCAT('Nation: ', n.n_name, ' | Region: ', r.r_name) AS location_info
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
    p.p_size BETWEEN 10 AND 20 
    AND p.p_retailprice > 25.00 
GROUP BY 
    s.s_name, p.p_name, n.n_name, r.r_name 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    total_available_quantity DESC, 
    average_supply_cost ASC;
