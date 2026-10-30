SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    TRIM(p.p_mfgr) AS manufacturer, 
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    CASE 
        WHEN p.p_size > 10 THEN 'Large' 
        WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium' 
        ELSE 'Small' 
    END AS size_category,
    CONCAT('Supplier details: ', s.s_name, ' - ', s.s_phone) AS supplier_info
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
    r.r_name LIKE '%Europe%' 
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, p.p_mfgr, p.p_size, p.p_comment, s.s_name, s.s_phone
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_supply_cost DESC, p.p_name;
