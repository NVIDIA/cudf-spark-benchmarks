SELECT 
    n.n_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    supplier s
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1995-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    revenue DESC
LIMIT 10;