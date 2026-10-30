SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name,
    o.o_orderkey,
    COUNT(l.l_orderkey) AS lineitem_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT(r.r_name, ': ', p.p_comment) AS detailed_comment
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
    p.p_size BETWEEN 1 AND 20
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate >= DATE '1997-01-01'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    c.c_name,
    o.o_orderkey,
    r.r_name,
    p.p_comment
ORDER BY 
    total_revenue DESC
LIMIT 50;