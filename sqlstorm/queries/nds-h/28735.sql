
SELECT 
    CONCAT('Supplier Name: ', s.s_name, ' | ', 
           'Part Name: ', p.p_name, ' | ', 
           'Total Supply Cost: $', CAST(SUM(ps.ps_supplycost) AS DECIMAL(12,2)), ' | ',
           'Region: ', r.r_name) AS benchmark_info,
    SUM(ps.ps_supplycost) AS total_supply_cost
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
    p.p_comment LIKE '%fragile%' 
GROUP BY 
    s.s_name, p.p_name, r.r_name
HAVING 
    SUM(ps.ps_supplycost) > 5000
ORDER BY 
    total_supply_cost DESC;
