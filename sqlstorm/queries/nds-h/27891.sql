SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Parts of type: ', p.p_type, ' - from manufacturer: ', p.p_mfgr) AS description,
    r.r_name AS region_name
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
    p.p_name LIKE '%widget%'
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_type, p.p_mfgr, r.r_name
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 100;
