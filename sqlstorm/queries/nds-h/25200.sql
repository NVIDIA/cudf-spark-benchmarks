SELECT 
    p.p_name,
    COUNT(distinct ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT(SUBSTRING(n.n_name, 1, 3), '-', SUBSTRING(r.r_name, 1, 3)) AS region_nation
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
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_name, short_comment, region_nation
HAVING 
    COUNT(distinct ps.ps_suppkey) > 10
ORDER BY 
    total_revenue DESC;
