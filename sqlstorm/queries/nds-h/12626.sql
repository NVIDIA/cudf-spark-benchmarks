SELECT 
    p.p_brand,
    p.p_type,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    avg_price DESC
LIMIT 10;