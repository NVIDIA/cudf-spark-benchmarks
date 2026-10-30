SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_cost_rank
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
WHERE 
    p.p_type LIKE '%metal%' 
    AND r.r_name IN (SELECT r_name FROM region WHERE r_comment LIKE '%important%')
GROUP BY 
    SUBSTRING(p.p_name, 1, 10)
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
