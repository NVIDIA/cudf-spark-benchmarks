SELECT 
    p.p_name,
    s.s_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    MAX(l.l_shipdate) AS last_ship_date,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Last Ship Date: ', MAX(l.l_shipdate)) AS shipment_info
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
    p.p_size > 10
    AND s.s_acctbal > 1000.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_returned_qty DESC, last_ship_date DESC
LIMIT 50;