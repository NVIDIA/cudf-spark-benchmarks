
SELECT 
    p.p_name,
    CONCAT('Supplier:', s.s_name, ', Address:', s.s_address) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    MAX(l.l_extendedprice) AS max_extended_price,
    AVG(l.l_discount) AS avg_discount,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment
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
WHERE 
    p.p_size IN (10, 20) AND
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, 
    s.s_name, 
    s.s_address, 
    p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, 
    max_extended_price ASC
LIMIT 100;
