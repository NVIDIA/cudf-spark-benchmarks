
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CASE 
        WHEN AVG(ps.ps_supplycost) > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS cost_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%widget%')
GROUP BY 
    p.p_name, 
    short_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_available_quantity DESC, 
    short_comment;
