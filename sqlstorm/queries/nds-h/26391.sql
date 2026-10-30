
SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info, 
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 100.00 
    AND s.s_acctbal > 5000.00 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_phone, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_price_after_discount DESC
LIMIT 10;
