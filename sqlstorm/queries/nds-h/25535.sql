SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS details,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    MAX(o.o_orderdate) AS last_order_date
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
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 1000
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, p.p_mfgr, p.p_brand, p.p_type
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_returned DESC, last_order_date DESC;
