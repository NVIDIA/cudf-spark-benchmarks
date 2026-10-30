SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier ', s.s_name, ' supplies ', p.p_name, ' with a price of ', CAST(ps.ps_supplycost AS STRING), ' per unit.') AS description,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(CASE WHEN l.l_discount > 0 THEN (l.l_extendedprice * (1 - l.l_discount)) ELSE l.l_extendedprice END) AS avg_price_after_discount
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    r.r_name LIKE 'Europ%'
GROUP BY 
    s.s_name, p.p_name, r.r_name, ps.ps_supplycost
ORDER BY 
    total_revenue DESC
LIMIT 10;
