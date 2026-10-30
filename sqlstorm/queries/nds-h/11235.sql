SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS sum_quantity, 
    SUM(l_extendedprice) AS sum_extended_price, 
    SUM(l_extendedprice * (1 - l_discount)) AS sum_discounted_price, 
    AVG(l_quantity) AS avg_quantity, 
    AVG(l_extendedprice) AS avg_extended_price, 
    COUNT(*) AS count_order_lines
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1997-01-01' AND l_shipdate <= DATE '1997-12-31'
GROUP BY 
    l_returnflag, l_linestatus
ORDER BY 
    l_returnflag, l_linestatus;