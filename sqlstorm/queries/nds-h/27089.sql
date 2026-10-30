SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS supplier_part_info,
    'Region: ' || r.r_name AS region_info,
    SUBSTR(l.l_comment, 1, 30) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_part_price
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
    l.l_shipdate BETWEEN '1996-01-01' AND '1997-01-01' 
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, s.s_name, r.r_name, l.l_comment
ORDER BY 
    total_revenue DESC
LIMIT 100;