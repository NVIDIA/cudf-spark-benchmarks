SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    l.l_shipmode, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Order: ', o.o_orderkey) AS order_info,
    CASE 
        WHEN l.l_returnflag = 'Y' THEN 'Returned'
        ELSE 'Not Returned' 
    END AS return_status
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_brand LIKE '%Brand%' 
    AND c.c_mktsegment = 'BUILDING'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    o.o_orderdate DESC, 
    p.p_name ASC
LIMIT 100;