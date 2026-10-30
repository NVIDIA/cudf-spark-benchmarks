SELECT 
    p.p_partkey, 
    p.p_name, 
    CONCAT(p.p_name, ' - ', p.p_container) AS full_description, 
    SUBSTRING(p.p_comment, 1, 15) AS short_comment, 
    r.r_name AS region_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost) AS total_supply_cost, 
    AVG(ps.ps_availqty) AS avg_available_quantity 
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
    p.p_size > 10 
    AND p.p_retailprice BETWEEN 50.00 AND 200.00 
GROUP BY 
    p.p_partkey, p.p_name, p.p_container, r.r_name, p.p_comment 
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 3 
ORDER BY 
    total_supply_cost DESC, 
    p.p_name ASC;
