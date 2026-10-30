SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUBSTR(p.p_comment, 1, 10) AS short_comment,
    r.r_name AS region_name,
    CASE 
        WHEN p.p_size > 10 THEN 'Large'
        WHEN p.p_size BETWEEN 6 AND 10 THEN 'Medium'
        ELSE 'Small' 
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
    p.p_retailprice > 50.00 
    AND p.p_name LIKE 'A%' 
    AND r.r_name IN ('Asia', 'Europe')
GROUP BY 
    p.p_name, r.r_name, p.p_size, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_qty DESC;
