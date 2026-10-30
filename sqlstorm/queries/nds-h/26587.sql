SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    REPLACE(UPPER(p.p_mfgr), 'INC', '') AS manufacturer_without_inc,
    LEFT(r.r_name, 3) AS region_prefix
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
    p.p_size > 20
GROUP BY 
    p.p_name, p.p_comment, p.p_mfgr, r.r_name
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_available_quantity DESC, supplier_count ASC
LIMIT 10;
