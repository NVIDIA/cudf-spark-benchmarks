
SELECT 
    LOWER(SUBSTRING(p.p_name, 1, 10)) AS short_name,
    COUNT(DISTINCT s.s_nationkey) AS unique_nations,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS supplier_part_info,
    REPLACE(p.p_comment, 'obsolete', 'current') AS updated_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    LOWER(SUBSTRING(p.p_name, 1, 10)), s.s_name, p.p_name, p.p_comment
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
ORDER BY 
    unique_nations DESC, short_name ASC;
