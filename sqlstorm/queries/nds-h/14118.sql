SELECT 
    n.n_name AS nation, 
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1996-01-01' 
    AND r.r_name = 'ASIA' 
GROUP BY 
    n.n_name 
ORDER BY 
    total_revenue DESC;
