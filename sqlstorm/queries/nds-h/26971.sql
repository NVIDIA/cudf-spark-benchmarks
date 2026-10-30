
SELECT 
    p.p_partkey, 
    p.p_name, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(l.l_extendedprice) AS average_extended_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%'
    AND p.p_retailprice BETWEEN 10.00 AND 50.00
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    SUBSTRING(p.p_comment, 1, 20)
HAVING 
    COALESCE(SUM(ps.ps_availqty), 0) > 5
ORDER BY 
    average_extended_price DESC, 
    p.p_name ASC;
