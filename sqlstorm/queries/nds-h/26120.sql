SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, '(', r.r_name, ')') AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTR(p.p_name, 1, 10) AS short_part_name,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01'
    AND p.p_brand LIKE 'Brand%'
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC, supplier_info ASC;