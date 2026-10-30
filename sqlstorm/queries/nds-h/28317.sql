SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT('Type: ', p.p_type, ', Container: ', p.p_container) AS product_details
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
    r.r_name LIKE '%North%'
    AND p.p_retailprice > 100
    AND p.p_size BETWEEN 1 AND 50
GROUP BY 
    p.p_partkey, p.p_name, p.p_type, p.p_container, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 3
ORDER BY 
    total_available_quantity DESC;
