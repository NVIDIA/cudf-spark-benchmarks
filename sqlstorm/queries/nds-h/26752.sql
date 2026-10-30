SELECT 
    CONCAT('Supplier Name: ', s_name, ' | Region: ', r_name) AS supplier_region_info,
    SUM(ps_supplycost * ps_availqty) AS total_supply_value,
    COUNT(DISTINCT p_partkey) AS unique_parts_supplied
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 10
ORDER BY 
    total_supply_value DESC, supplier_region_info;
