SELECT 
    p.p_partkey,
    LENGTH(p.p_name) AS name_length,
    UPPER(p.p_brand) AS upper_brand,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
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
    p.p_size > 10 AND 
    p.p_retailprice BETWEEN 50 AND 200 AND 
    r.r_name LIKE 'Eu%'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_comment, 
    r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    name_length DESC, 
    upper_brand ASC;
