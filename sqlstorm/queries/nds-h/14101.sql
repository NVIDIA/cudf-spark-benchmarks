SELECT 
    AVG(o_totalprice) AS avg_total_price,
    COUNT(*) AS order_count,
    SUM(l_quantity) AS total_quantity,
    SUM(l_extendedprice) AS total_extended_price
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    o.o_orderstatus;