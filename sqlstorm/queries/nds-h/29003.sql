SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 20) AS brief_comment,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 20
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1997-10-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, p.p_comment, r.r_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 100;