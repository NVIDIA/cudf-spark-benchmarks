SELECT 
    p.p_partkey, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    AVG(l.l_extendedprice) AS avg_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey
ORDER BY 
    total_avail_qty DESC
LIMIT 100;
