
SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name) AS details
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
    p.p_brand LIKE 'Brand%'
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, p.p_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, short_comment ASC
LIMIT 10;
