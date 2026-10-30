SELECT 
    CONCAT(s.s_name, ' - ', p.p_name, ' [', p.p_brand, ']') AS supplier_product,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND s.s_comment LIKE '%high priority%'
GROUP BY 
    s.s_name, p.p_name, p.p_brand
ORDER BY 
    total_quantity DESC, last_order_date DESC
LIMIT 10;