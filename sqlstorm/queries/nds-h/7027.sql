SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS revenue,
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
    o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    revenue DESC, order_count DESC
LIMIT 10;