SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    SUM(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) AS total_revenue_with_tax,
    o.o_orderdate,
    c.c_mktsegment 
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    l.l_orderkey, o.o_orderdate, c.c_mktsegment 
ORDER BY 
    revenue DESC
LIMIT 100;
