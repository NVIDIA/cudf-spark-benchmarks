
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderdate AS order_date, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Customer: ', c.c_name) AS descriptive_label,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Order Open'
        WHEN o.o_orderstatus = 'F' THEN 'Order Filled'
        ELSE 'Order Unknown'
    END AS order_status_description
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    p.p_comment LIKE '%soft%'
    AND c.c_mktsegment = 'BUILDING'
    AND s.s_comment NOT LIKE '%limited%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderdate, o.o_orderstatus
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
ORDER BY 
    revenue DESC, order_date ASC;
