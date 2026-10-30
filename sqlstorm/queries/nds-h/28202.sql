SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(ps_supplycost) AS max_supply_cost,
    AVG(p_retailprice) AS avg_retail_price,
    CONCAT(r_name, ' - ', n_name) AS region_nation
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
    AND p_comment LIKE '%fragile%'
GROUP BY 
    short_name, region_nation
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    avg_retail_price DESC, max_supply_cost ASC;
