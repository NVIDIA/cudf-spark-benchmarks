
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    n.n_name AS nation_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    AND l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
GROUP BY 
    c.c_name, o.o_orderkey, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;
