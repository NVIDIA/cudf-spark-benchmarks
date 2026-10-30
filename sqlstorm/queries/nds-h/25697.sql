SELECT 
    p.p_partkey,
    UPPER(p.p_name) AS uppercase_part_name,
    CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type,
    REPLACE(SUBSTRING(p.p_comment, 1, 15), ' ', '-') AS modified_comment,
    COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_value,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment, s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_supply_value DESC, uppercase_part_name ASC;
