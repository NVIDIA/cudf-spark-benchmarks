SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    MIN(l.l_shipdate) AS earliest_ship_date,
    MAX(l.l_shipdate) AS latest_ship_date,
    n.n_name AS nation_name,
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
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%hardware%'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    SUBSTRING(p_name, 1, 10), 
    n.n_name, 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_supply_cost DESC;
