
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_quantity ELSE 0 END) AS total_open_order_quantity,
    MAX(o.o_orderdate) AS last_order_date,
    CONCAT('Supplier ', s.s_name, ' - ', r.r_name) AS supplier_region_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_container LIKE '%BOX%' 
    AND r.r_name IN ('Europe', 'Asia')
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_quantity ELSE 0 END) > 100
ORDER BY 
    total_open_order_quantity DESC, short_name ASC;
