SELECT 
    n.n_name AS nation, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(o.o_totalprice) AS avg_order_value, 
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    n.n_name IN ('GERMANY', 'FRANCE')
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;