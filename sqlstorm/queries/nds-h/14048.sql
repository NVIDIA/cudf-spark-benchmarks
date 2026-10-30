SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    l_shipdate >= DATE '1997-01-01' 
    AND l_shipdate < DATE '1997-12-31' 
GROUP BY 
    n_name 
ORDER BY 
    revenue DESC 
LIMIT 10;