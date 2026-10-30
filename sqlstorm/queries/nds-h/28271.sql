SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ' | Region: ', r.r_name, ' | Comment: ', s.s_comment) AS supplier_info,
    SUBSTRING(l.l_comment, 1, 20) AS line_comment_excerpt,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_revenue,
    MAX(l.l_shipdate) AS latest_ship_date
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
    p.p_type LIKE 'PROMO%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, r.r_name, s.s_comment, l.l_comment
ORDER BY 
    total_orders DESC, avg_revenue DESC
LIMIT 10;
