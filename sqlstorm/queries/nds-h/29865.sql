SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ', located in ', r.r_name) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_brand LIKE '%BRAND%'
    AND p.p_comment NOT LIKE '%defective%'
    AND r.r_name IN ('EUROPE', 'ASIA')
GROUP BY 
    s.s_name, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC, unique_parts ASC;
