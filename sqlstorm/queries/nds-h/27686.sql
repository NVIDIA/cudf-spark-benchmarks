SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderdate AS order_date, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Region: ', r.r_name, '; Nation: ', n.n_name) AS geographical_info,
    LEFT(p.p_comment, 25) AS part_comment_snippet
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
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderdate, r.r_name, n.n_name, p.p_comment
ORDER BY 
    total_revenue DESC
LIMIT 10;