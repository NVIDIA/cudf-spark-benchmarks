SELECT 
    p.p_name AS part_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    SUM(l.l_quantity) AS total_quantity_ordered,
    r.r_name AS region_name
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    customer c ON l.l_orderkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-12-31' 
GROUP BY 
    p.p_name, r.r_name 
HAVING 
    SUM(l.l_quantity) > 1000 
ORDER BY 
    region_name, supplier_count DESC;