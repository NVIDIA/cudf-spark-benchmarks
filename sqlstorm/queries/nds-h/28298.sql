SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Region: ', r.r_name, ' - Comment: ', r.r_comment) AS region_details
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
    p.p_retailprice > 50.00
    AND s.s_acctbal < 1000.00
GROUP BY 
    short_name, region_details
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    short_name ASC, average_supply_cost DESC;
