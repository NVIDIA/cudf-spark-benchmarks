SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    n.n_name
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
    o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
AND 
    n.n_regionkey = (
        SELECT r_regionkey FROM region WHERE r_name = 'EUROPE'
    )
GROUP BY 
    c.c_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
