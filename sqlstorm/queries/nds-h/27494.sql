SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    CONCAT(p.p_name, ' supplied by ', s.s_name, ' to customer ', c.c_name, ' in order ', o.o_orderkey) AS order_description,
    LEFT(o.o_comment, 35) AS order_comment_snippet,
    LENGTH(o.o_comment) AS order_comment_length,
    COUNT(DISTINCT l.l_orderkey) AS total_line_items,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
WHERE 
    p.p_size >= 10 AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_comment
ORDER BY 
    total_revenue DESC
LIMIT 50;