
SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_suppkey) > 5 THEN 'High Supply'
        WHEN COUNT(DISTINCT ps.ps_suppkey) BETWEEN 3 AND 5 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_status,
    REGEXP_REPLACE(LOWER(p.p_name), '[aeiou]', '*', 'g') AS masked_part_name,
    SUBSTR(p.p_comment, 1, 20) AS brief_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name LIKE 'C%' 
    AND p.p_size BETWEEN 1 AND 20
GROUP BY 
    p.p_brand, 
    p.p_name, 
    p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
