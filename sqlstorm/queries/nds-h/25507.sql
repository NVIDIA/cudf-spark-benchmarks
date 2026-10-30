SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name, ', Part: ', p.p_name, ', Total Quantity: ', SUM(l.l_quantity), ', Total Orders: ', COUNT(DISTINCT o.o_orderkey)) AS summary
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_mfgr LIKE 'Manufacturer%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, region_name, supplier_name;