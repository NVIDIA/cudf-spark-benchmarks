SELECT 
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND 
    l.l_shipdate < DATE '1998-01-01' AND
    p.p_size = 15
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    revenue DESC
LIMIT 10;