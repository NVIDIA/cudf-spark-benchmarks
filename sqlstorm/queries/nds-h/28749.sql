SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    LENGTH(p_comment) AS comment_length,
    CONCAT(r_name, ' ', n_name) AS region_nation,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    AVG(ps_supplycost) AS avg_supply_cost
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
    p_size BETWEEN 10 AND 20
GROUP BY 
    short_name, comment_length, region_nation
HAVING 
    AVG(ps_supplycost) > 50.00
ORDER BY 
    comment_length DESC, supplier_count ASC;
