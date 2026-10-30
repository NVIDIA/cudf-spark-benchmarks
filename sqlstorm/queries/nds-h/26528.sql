
SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' (', r.r_name, ')') AS supplier_info,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    COUNT(DISTINCT l.l_orderkey) AS distinct_line_items
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
    p.p_comment LIKE '%quality%'
    AND l.l_shipmode IN ('AIR', 'TRAIN')
GROUP BY 
    s.s_name, n.n_name, r.r_name
HAVING 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_returned_quantity DESC, total_orders ASC;
