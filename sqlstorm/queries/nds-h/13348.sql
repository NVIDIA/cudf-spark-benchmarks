SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS average_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
ORDER BY 
    total_available DESC
LIMIT 10;
