SELECT 
    p.p_name,
    s.s_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name) AS detail_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    MAX(l.l_discount) AS max_discount
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
    p.p_size >= 10 AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, short_comment, detail_info
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, average_price ASC;
