SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Order: ', o.o_orderkey, ' / Customer: ', c.c_name) AS order_customer_info
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%E%' 
    AND l.l_shipmode IN ('MAIL', 'SHIP')
    AND o.o_orderdate >= '1996-01-01' 
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, r.r_name, p.p_comment
ORDER BY 
    revenue DESC, order_count DESC
LIMIT 10;