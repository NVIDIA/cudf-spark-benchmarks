SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN SUM(ps.ps_supplycost) > 5000 THEN 'High Cost' 
        ELSE 'Low Cost' 
    END AS cost_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%plastic%'
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
