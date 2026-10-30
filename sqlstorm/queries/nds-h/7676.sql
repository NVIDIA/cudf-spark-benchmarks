SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    AND l.l_shipmode IN ('AIR', 'SHIP')
    AND l.l_returnflag = 'N'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC, nation_name ASC, region_name ASC
LIMIT 10;