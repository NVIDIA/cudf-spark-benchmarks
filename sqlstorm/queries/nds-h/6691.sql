SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_quantity) AS total_quantity_sold
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
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE 'Europe%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND l.l_shipmode IN ('AIR', 'SEA')
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(o.o_totalprice) > 100000
ORDER BY 
    total_revenue DESC, unique_customers DESC
LIMIT 10;