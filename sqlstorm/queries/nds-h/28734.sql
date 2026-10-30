SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 15) AS part_comment_preview,
    CONCAT('Region: ', r.r_name, ', Customer: ', c.c_name) AS customer_region_info
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
    r.r_name LIKE '%West%'
    AND o.o_orderstatus = 'O'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, p.p_comment
ORDER BY 
    total_revenue DESC, total_orders ASC
LIMIT 100;
