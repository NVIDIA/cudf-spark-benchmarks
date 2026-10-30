SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    SUBSTRING(o.o_comment, 1, 20) AS order_comment_excerpt,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue
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
    LENGTH(s.s_name) > 10
    AND o.o_orderdate >= '1996-01-01'
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_comment
HAVING 
    SUM(l.l_discount) > 0.1
ORDER BY 
    total_revenue DESC;