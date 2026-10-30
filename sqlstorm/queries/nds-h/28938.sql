SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_nationkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(CASE WHEN LENGTH(s.s_name) > 10 THEN LENGTH(s.s_name) END) AS avg_supplier_name_length,
    MAX(CASE WHEN p.p_size < 20 THEN p.p_retailprice END) AS max_retail_price_small_parts
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_type LIKE '%metal%'
    AND n.n_name IN (SELECT r_name FROM region WHERE r_regionkey < 3)
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 2
ORDER BY 
    total_available_quantity DESC, 
    avg_supplier_name_length DESC
LIMIT 10;
