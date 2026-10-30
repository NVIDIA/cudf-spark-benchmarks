SELECT 
    l.l_shipmode, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_revenue,
    SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS normal_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    l.l_shipmode
ORDER BY 
    l.l_shipmode;
