SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey AS order_id, 
    SUM(l.l_quantity) AS total_quantity, 
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue, 
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
    l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, part_name ASC;