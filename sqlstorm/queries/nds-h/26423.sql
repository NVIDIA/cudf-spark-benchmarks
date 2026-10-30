SELECT 
    c.c_custkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    SUBSTRING(c.c_address, 1, 20) AS short_address,
    n.n_name AS nation,
    p.p_brand AS brand,
    COUNT(distinct o.o_orderkey) AS order_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    AND p.p_type LIKE '%metal%'
GROUP BY 
    c.c_custkey, c.c_name, short_address, n.n_name, p.p_brand
ORDER BY 
    revenue DESC, order_count DESC
LIMIT 10;