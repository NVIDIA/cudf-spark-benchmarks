
SELECT 
    p.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    SUM(l.l_extendedprice) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
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
    p.p_size > 10 
    AND (l.l_shipmode = 'AIR' OR l.l_shipmode = 'SHIP')
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, r.r_name, s.s_name, s.s_address, p.p_comment
HAVING 
    SUM(l.l_extendedprice) > 10000
ORDER BY 
    total_revenue DESC;
