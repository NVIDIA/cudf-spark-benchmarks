
SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Order Date: ', o.o_orderdate, ' | Total Price: ', o.o_totalprice) AS order_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS unique_orders
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
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    AND p.p_comment LIKE '%special%'
GROUP BY 
    s.s_name, p.p_name, o.o_orderdate, o.o_totalprice
ORDER BY 
    total_revenue DESC, unique_orders DESC
LIMIT 100;
