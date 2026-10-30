SELECT 
    n.n_name AS nation_name,
    SUM(o.o_totalprice) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_per_order,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    p.p_brand AS brand_name
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_type LIKE 'SMALL%'
GROUP BY 
    n.n_name, p.p_brand
ORDER BY 
    total_revenue DESC, unique_customers DESC
LIMIT 10;