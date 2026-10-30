SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    CONCAT('Supplier count for part ', p.p_name, ': ', COUNT(DISTINCT s.s_suppkey)) AS supplier_info,
    UPPER(p.p_brand) AS brand_uppercase,
    REPLACE(p.p_comment, 'standard', 'premium') AS updated_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 30
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 500
ORDER BY 
    total_supply_cost DESC;
