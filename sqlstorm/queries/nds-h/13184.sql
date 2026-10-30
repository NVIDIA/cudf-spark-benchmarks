SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(o.o_totalprice) AS average_order_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
