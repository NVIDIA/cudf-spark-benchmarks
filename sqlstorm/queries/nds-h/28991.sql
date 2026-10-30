SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 10), '...') AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(p.p_retailprice) AS min_retail_price,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_size BETWEEN 1 AND 100
    AND p.p_type LIKE '%plastic%'
GROUP BY 
    short_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
