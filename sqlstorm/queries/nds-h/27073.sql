SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT_WS(' - ', r.r_name, n.n_name, s.s_address) AS supplier_location,
    AVG(s.s_acctbal) AS average_acctbal
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name, s.s_address
ORDER BY 
    total_revenue DESC
LIMIT 10;