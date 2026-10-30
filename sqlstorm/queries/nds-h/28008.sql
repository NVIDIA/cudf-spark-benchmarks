SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    SUM(CASE WHEN l.l_returnflag != 'R' THEN l.l_quantity ELSE 0 END) AS total_sold,
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    p.p_brand LIKE 'Brand%'
    AND o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    s.s_name, 
    p.p_name, 
    r.r_name, 
    n.n_name
ORDER BY 
    order_count DESC, 
    last_ship_date DESC;