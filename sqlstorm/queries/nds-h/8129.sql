SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    n.n_name AS nation_name,
    o.o_orderdate AS order_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    p.p_type AS part_type
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    p.p_size > 10
GROUP BY 
    c.c_name, n.n_name, o.o_orderdate, p.p_type
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 100;