
SELECT 
    p.p_name AS part_name, 
    CONCAT(s.s_name, ' (', s.s_address, ', ', r.r_name, ')') AS supplier_info, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    SUBSTRING(p.p_comment, 1, 10) AS comment_excerpt
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
    p.p_type LIKE '%brass%'
AND 
    o.o_orderdate >= DATE '1997-01-01'
AND 
    o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_address, r.r_name, p.p_comment
ORDER BY 
    total_revenue DESC
LIMIT 10;
