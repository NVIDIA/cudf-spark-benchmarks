SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    o.o_totalprice, 
    l.l_quantity, 
    l.l_extendedprice, 
    l.l_discount, 
    l.l_tax, 
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CONCAT('Part Name: ', p.p_name, ', Supplied by: ', s.s_name) AS part_supplier_info
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND l.l_discount > 0.10 
ORDER BY 
    return_status, 
    o.o_totalprice DESC;