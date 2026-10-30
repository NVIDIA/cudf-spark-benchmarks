
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length
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
    o.o_totalprice > 1000
GROUP BY 
    p.p_name, r.r_name, n.n_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_quantity DESC, supplier_count ASC;
