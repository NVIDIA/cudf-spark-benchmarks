SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS manufacturer_info,
    REPLACE(p.p_comment, 'interesting', 'fascinating') AS modified_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_supplycost ELSE 0 END) AS total_supply_cost,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 5
GROUP BY 
    p.p_partkey, short_name, manufacturer_info, modified_comment
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 2
ORDER BY 
    total_supply_cost DESC, p.p_partkey ASC
LIMIT 10;
