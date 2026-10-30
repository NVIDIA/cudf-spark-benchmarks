
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    SUBSTRING(p.p_name, 1, 15) AS truncated_part_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    n.n_name LIKE '%land%' 
    AND p.p_type IN ('metal', 'plastic')
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    s.s_name, n.n_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC
LIMIT 10;
