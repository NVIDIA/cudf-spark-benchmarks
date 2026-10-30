SELECT 
    l_shipmode,
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS returned_quantity,
    SUM(l_quantity) AS total_quantity,
    COUNT(DISTINCT o_orderkey) AS order_count
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    o_orderdate >= DATE '1997-01-01' AND o_orderdate < DATE '1998-01-01'
GROUP BY 
    l_shipmode
ORDER BY 
    l_shipmode;