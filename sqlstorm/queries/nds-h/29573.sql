SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    o.o_orderdate AS order_date,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Order: ', o.o_orderkey) AS order_summary,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Fully Filled'
        WHEN o.o_orderstatus = 'P' THEN 'Partially Filled'
        ELSE 'Unknown Status'
    END AS order_status_description
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
    p.p_name LIKE '%widget%'
    AND c.c_mktsegment = 'BUILDING'
ORDER BY 
    order_date DESC
LIMIT 100;
