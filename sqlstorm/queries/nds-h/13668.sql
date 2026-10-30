SELECT 
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' 
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    p.p_brand,
    p.p_type
ORDER BY 
    revenue DESC;
