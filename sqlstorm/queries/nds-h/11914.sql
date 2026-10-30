SELECT 
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_mfgr
ORDER BY 
    supplier_count DESC;
