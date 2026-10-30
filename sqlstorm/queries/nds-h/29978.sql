SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT(c.c_name, ' - ', c.c_address) AS customer_info,
    REPLACE(REPLACE(REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9 ]', ''), ' ', '_'), '_+', '_') AS sanitized_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 50.00
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name, s.s_name, c.c_name, c.c_address, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_orders DESC, avg_extended_price ASC;
