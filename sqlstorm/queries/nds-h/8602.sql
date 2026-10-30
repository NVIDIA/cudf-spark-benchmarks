SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    SUM(CASE WHEN l.l_shipmode = 'AIR' THEN l.l_extendedprice ELSE 0 END) AS air_shipping_revenue,
    SUM(CASE WHEN l.l_shipmode = 'GROUND' THEN l.l_extendedprice ELSE 0 END) AS ground_shipping_revenue
FROM 
    nation n
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;