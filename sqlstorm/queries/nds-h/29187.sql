SELECT 
    p.p_name AS part_name,
    p.p_brand AS part_brand,
    p.p_type AS part_type,
    CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(CASE WHEN c.c_mktsegment = 'AUTOMOBILE' THEN o.o_totalprice ELSE NULL END) AS avg_auto_order_value
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
GROUP BY 
    p.p_name, p.p_brand, p.p_type, s.s_name, s.s_address
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_sales DESC, total_orders DESC
LIMIT 20;
