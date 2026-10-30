
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Delivery Status: ', 
           CASE 
               WHEN l.l_returnflag = 'R' THEN 'Returned'
               ELSE 'Delivered'
           END) AS delivery_status,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    s.s_comment LIKE '%reliable%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    s.s_name, p.p_name, l.l_returnflag
ORDER BY 
    total_revenue DESC, delivery_status;
