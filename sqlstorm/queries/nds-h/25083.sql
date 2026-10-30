SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    LEFT(p.p_comment, 10) AS short_comment, 
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
    p.p_size > 20 
    AND s.s_acctbal > 5000 
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment 
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 2 
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
