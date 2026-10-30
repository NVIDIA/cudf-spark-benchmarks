SELECT 
    p.p_name,
    s.s_name,
    SUBSTR(p.p_comment, 1, 15) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROUND(AVG(l.l_extendedprice), 2) AS avg_extended_price
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
    s.s_comment LIKE '%fragile%'
    AND l.l_shipmode IN ('AIR', 'GROUND')
GROUP BY 
    p.p_name, s.s_name, short_comment
HAVING 
    AVG(l.l_discount) > 0.10
ORDER BY 
    order_count DESC, avg_extended_price DESC
LIMIT 10;
