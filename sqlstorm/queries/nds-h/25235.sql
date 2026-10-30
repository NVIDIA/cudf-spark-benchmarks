SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    COUNT(l.l_orderkey) AS line_item_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_quantity) AS min_quantity,
    CONCAT('Part: ', p.p_name, ', Prod: ', s.s_name) AS part_supplier_info,
    CONCAT('Customer: ', c.c_name, ', Order ID: ', o.o_orderkey) AS customer_order_info
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
    p.p_mfgr = 'ManufacturerX' AND 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' 
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_extended_price DESC;