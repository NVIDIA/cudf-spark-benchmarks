SELECT 
    CONCAT_WS(' ', c.c_name, 'from', n.n_name, 'in', r.r_name) AS supplier_details,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returned_orders
FROM 
    customer c 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    r.r_name LIKE 'S%' 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
GROUP BY 
    c.c_name, n.n_name, r.r_name 
ORDER BY 
    total_revenue DESC;