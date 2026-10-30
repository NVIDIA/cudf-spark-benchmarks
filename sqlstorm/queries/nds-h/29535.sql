SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    n.n_name,
    r.r_name,
    COUNT(*) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name, ', Customer: ', c.c_name) AS summary
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_type LIKE '%metal%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, n.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;