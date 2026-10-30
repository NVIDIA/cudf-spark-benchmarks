SELECT 
    p.p_name,
    SUBSTR(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS product_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(CASE WHEN s.s_nationkey = n.n_nationkey THEN s.s_name ELSE NULL END) AS prominent_supplier
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    LENGTH(p.p_name) > 5
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, p.p_brand, p.p_type, p.p_comment
ORDER BY 
    supplier_count DESC, average_supply_cost ASC
LIMIT 10;
