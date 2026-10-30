SELECT 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    o.o_orderstatus
ORDER BY 
    total_revenue DESC;