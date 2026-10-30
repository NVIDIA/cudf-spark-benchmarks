SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS average_order_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    nation n
INNER JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
INNER JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
INNER JOIN 
    part p ON ps.ps_partkey = p.p_partkey
INNER JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
INNER JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
    AND l.l_returnflag = 'N'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;