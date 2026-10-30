
SELECT 
    n.n_name AS nation_name,
    SUM(o.o_totalprice) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(l.l_orderkey) AS total_line_items
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
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND l.l_shipmode = 'AIR'
GROUP BY 
    n.n_name
HAVING 
    SUM(o.o_totalprice) > 1000000
ORDER BY 
    total_revenue DESC;
