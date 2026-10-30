SELECT 
    p.p_name,
    s.s_name,
    CONCAT(c.c_name, ' (', SUBSTRING(c.c_address FROM 1 FOR 10), '... - ', c.c_phone, ')') AS customer_info,
    COUNT(o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_discount) AS max_discount,
    p.p_comment
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
    p.p_size > 10 AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    c.c_address, 
    c.c_phone, 
    p.p_comment
ORDER BY 
    total_revenue DESC, 
    order_count DESC
LIMIT 10;