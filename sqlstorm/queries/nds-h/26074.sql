
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE 
            WHEN LENGTH(p.p_comment) > 15 THEN 1 
            ELSE 0 
        END) AS long_comments,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
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
    p.p_retailprice > 100.00 AND 
    UPPER(n.n_name) LIKE 'A%'
GROUP BY 
    p.p_name, p.p_comment, r.r_name, p.p_partkey
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    long_comments DESC, supplier_count ASC;
