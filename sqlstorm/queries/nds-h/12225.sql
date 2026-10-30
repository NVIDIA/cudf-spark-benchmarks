SELECT 
    COUNT(DISTINCT l_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    AVG(l_quantity) AS avg_quantity_per_line
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_returnflag, l_linestatus
ORDER BY 
    total_revenue DESC;