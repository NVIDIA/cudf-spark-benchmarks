
SELECT 
    SUBSTRING(p.p_name, 1, 20) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location,
    LENGTH(p.p_comment) AS comment_length,
    CASE 
        WHEN p.p_size <= 10 THEN 'Small'
        WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
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
GROUP BY 
    p.p_name, r.r_name, n.n_name, p.p_comment, p.p_size
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    avg_supply_cost DESC, comment_length DESC;
