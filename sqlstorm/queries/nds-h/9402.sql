SELECT 
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS average_order_value
FROM 
    region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01'
    AND l.l_shipdate < DATE '1997-12-31'
    AND n.n_name = 'USA'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;