SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    MAX(CASE 
            WHEN LENGTH(p.p_comment) > 20 THEN SUBSTRING(p.p_comment, 1, 20) || '...'
            ELSE p.p_comment 
        END) AS truncated_comment,
    r.r_name AS region_name 
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
    p.p_retailprice > 100.00 
    AND r.r_name LIKE 'Eu%'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_available_quantity DESC, 
    p.p_name;
