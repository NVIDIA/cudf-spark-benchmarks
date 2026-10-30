SELECT 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(l.l_discount) AS avg_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    total_availqty DESC;
