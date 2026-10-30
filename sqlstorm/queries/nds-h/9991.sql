SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    COUNT(DISTINCT l.l_orderkey) AS unique_line_items,
    AVG(o.o_totalprice) AS average_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    AND l.l_shipmode IN ('SHIP', 'AIR', 'FOB') 
    AND l.l_returnflag = 'N'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;