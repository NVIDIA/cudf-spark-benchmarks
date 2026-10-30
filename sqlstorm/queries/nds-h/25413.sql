SELECT 
    p.p_name,
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_info,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(p.p_size) AS min_part_size
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
    p.p_type LIKE '%steel%'
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    avg_supply_cost DESC, num_suppliers ASC
LIMIT 50;
