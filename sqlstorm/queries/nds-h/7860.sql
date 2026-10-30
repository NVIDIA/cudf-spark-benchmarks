SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice / NULLIF(l.l_quantity, 0)) AS avg_price_per_qty,
    r.r_name AS region_name,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
    AND s.s_acctbal > 1000
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC, customer_count DESC
LIMIT 10;