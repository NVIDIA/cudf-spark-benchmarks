SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name,
    CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS supplier_full_address
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%BRASS%'
    AND l.l_shipdate >= DATE '1997-01-01'
    AND l.l_shipdate < DATE '1997-12-31'
GROUP BY 
    c.c_name, s.s_name, p.p_name, r.r_name, s.s_address, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 100;