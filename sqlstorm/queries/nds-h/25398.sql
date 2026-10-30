SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region_name,
    SUBSTRING(p.p_name, 1, 10) AS short_product_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND p.p_type LIKE '%metal%'
GROUP BY 
    c.c_name, c.c_address, r.r_name, short_product_name
ORDER BY 
    total_revenue DESC
LIMIT 10;