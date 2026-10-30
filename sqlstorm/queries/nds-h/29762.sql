SELECT 
    CONCAT(p.p_name, ' (', p.p_container, ') - ', p.p_comment) AS detailed_part_description,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity_per_line_item
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
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'Europe%'
AND 
    o.o_orderdate >= '1997-01-01' 
AND 
    o.o_orderdate < '1998-01-01'
GROUP BY 
    detailed_part_description, supplier_name, region_name
ORDER BY 
    total_revenue DESC, average_quantity_per_line_item DESC;