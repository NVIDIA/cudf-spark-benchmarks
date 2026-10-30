SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(CASE 
            WHEN LENGTH(p.p_comment) > 20 THEN LENGTH(p.p_comment)
            ELSE 0 
        END) AS avg_comment_length
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_shipmode IN ('Air', 'Ground')
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC, order_count DESC;