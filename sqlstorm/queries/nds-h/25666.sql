SELECT 
    SUBSTRING(p.p_name, 1, 15) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS mfgr_brand_info,
    MAX(o.o_orderdate) AS latest_order_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 50.00
    AND o.o_orderstatus = 'O'
GROUP BY 
    SUBSTRING(p.p_name, 1, 15), p.p_mfgr, p.p_brand
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    avg_supply_cost DESC, latest_order_date DESC
LIMIT 
    10;
