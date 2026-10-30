
SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    LENGTH(p.p_name) AS name_length, 
    CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type, 
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    r.r_name AS region_name
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
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE 'S%' 
    AND s.s_comment NOT LIKE '%obsolete%'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, p.p_brand, p.p_type
ORDER BY 
    total_revenue DESC
LIMIT 10;
