SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    LENGTH(p_comment) AS comment_length,
    COUNT(DISTINCT s_name) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost,
    REPLACE(UPPER(n_name), ' ', '_') AS formatted_nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p_size BETWEEN 1 AND 50
GROUP BY 
    short_name, comment_length, formatted_nation_name
HAVING 
    AVG(ps_supplycost) > 100.00 
ORDER BY 
    comment_length DESC, supplier_count ASC;
