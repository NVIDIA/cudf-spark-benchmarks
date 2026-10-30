SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(year from o_orderdate) AS year
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n_name, year
ORDER BY 
    revenue DESC
LIMIT 10;
