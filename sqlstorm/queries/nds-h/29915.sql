
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(CASE WHEN LENGTH(p.p_comment) > 15 THEN SUBSTR(p.p_comment, 1, 15) || '...' ELSE p.p_comment END) AS truncated_comment,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info
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
    p.p_retailprice > 50.00 AND
    LENGTH(p.p_name) > 10
GROUP BY 
    p.p_name, p.p_brand, r.r_name, n.n_name
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC
LIMIT 10;
