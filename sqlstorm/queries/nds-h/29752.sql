SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_qty, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    MAX(SUBSTRING(p.p_comment, 1, 20)) AS comment_excerpt,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_name LIKE '%Widget%'
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 500
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC
LIMIT 10;
