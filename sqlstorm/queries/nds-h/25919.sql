SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_and_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(ps.ps_availqty) AS max_available_quantity,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    RANK() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS cost_rank
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
    p.p_size > 10 
    AND n.n_name LIKE 'A%' 
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
HAVING 
    COUNT(ps.ps_suppkey) > 5
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;
