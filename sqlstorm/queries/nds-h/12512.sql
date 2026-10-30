SELECT 
    p.p_brand,
    p.p_type,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(s.s_acctbal) AS average_supplier_acctbal
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    total_quantity DESC
LIMIT 10;
