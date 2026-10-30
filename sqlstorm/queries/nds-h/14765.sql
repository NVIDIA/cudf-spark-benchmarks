SELECT 
    l_linenumber, 
    SUM(l_extendedprice) AS total_revenue,
    COUNT(DISTINCT o_orderkey) AS order_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
GROUP BY 
    l_linenumber
ORDER BY 
    total_revenue DESC
LIMIT 100;