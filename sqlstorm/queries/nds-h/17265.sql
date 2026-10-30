SELECT 
    p.p_name, 
    sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name = 'GERMANY' 
    AND l.l_shipdate >= '1994-01-01' 
    AND l.l_shipdate < '1995-01-01'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC;
