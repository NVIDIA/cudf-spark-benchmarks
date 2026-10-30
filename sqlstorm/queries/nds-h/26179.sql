
SELECT 
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_quantity) AS total_quantity,
    CONCAT('Total for ', p.p_name, ' is ', SUM(l.l_extendedprice), ' with average supply cost of ', AVG(ps.ps_supplycost)) AS summary_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND p.p_mfgr LIKE 'Manufacturer%'
GROUP BY 
    p.p_brand, p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_quantity DESC
LIMIT 10;
