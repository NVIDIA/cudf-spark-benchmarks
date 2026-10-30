SELECT 
    AVG(l_extendedprice * (1 - l_discount)) AS avg_discounted_price,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_quantity) AS total_quantity_sold
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    l_shipdate >= DATE '1997-01-01' AND l_shipdate <= DATE '1997-12-31'
GROUP BY 
    l_returnflag, l_linestatus
ORDER BY 
    avg_discounted_price DESC;