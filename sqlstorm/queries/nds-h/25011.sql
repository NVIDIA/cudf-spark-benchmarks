SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS mfgr_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(o.o_totalprice) AS total_order_value,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    short_name, mfgr_info
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_order_value DESC
LIMIT 10;
