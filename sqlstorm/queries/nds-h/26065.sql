SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region_name,
    CONCAT(s.s_address, ' - ', s.s_phone) AS supplier_contact_info,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderstatus = 'O'
    AND l.l_shipdate >= '1996-01-01'
    AND l.l_shipdate <= '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, s.s_address, s.s_phone, p.p_comment
ORDER BY 
    total_revenue DESC, part_name ASC;