
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_type, 
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT(p.p_name, ' - ', p.p_type) AS product_description,
    LEFT(n.n_comment, 50) AS short_nation_comment
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
    p.p_size BETWEEN 10 AND 20 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name, p.p_type, s.s_name, n.n_name, r.r_name, 
    CONCAT(p.p_name, ' - ', p.p_type), LEFT(n.n_comment, 50)
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC, p.p_name ASC;
