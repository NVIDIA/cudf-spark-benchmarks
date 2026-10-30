
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_totalprice) AS max_order_price,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name) AS supplier_product_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100 AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_orders DESC,
    total_available_qty ASC;
