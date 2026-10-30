SELECT 
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN c.c_mktsegment = 'BUILDING' THEN l.l_quantity ELSE 0 END) AS building_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1996-01-01' 
    AND l.l_shipdate < DATE '1997-01-01'
    AND p.p_size = 15
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;