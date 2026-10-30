SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    SUM(l.l_quantity) AS total_quantity_sold
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND l.l_shipdate > l.l_commitdate 
GROUP BY 
    n.n_name, r.r_name 
ORDER BY 
    total_revenue DESC, unique_customers DESC 
LIMIT 10;