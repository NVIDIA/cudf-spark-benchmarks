SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    REPLACE(REPLACE(p.p_comment, 'quality', 'excellence'), 'defective', 'imperfect') AS modified_comment,
    CONCAT('Order ', o.o_orderkey, ' - ', p.p_name) AS order_part_description
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
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, modified_comment
ORDER BY 
    revenue DESC
LIMIT 10;