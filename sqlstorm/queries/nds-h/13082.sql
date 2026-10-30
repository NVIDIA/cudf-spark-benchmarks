SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(year from o_orderdate) AS year
FROM 
    supplier s
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o_orderdate >= DATE '1994-01-01' AND o_orderdate < DATE '1995-01-01'
GROUP BY 
    n_name, year
ORDER BY 
    revenue DESC, n_name;
