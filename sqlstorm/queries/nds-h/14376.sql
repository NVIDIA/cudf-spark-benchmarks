SELECT 
    l_returnflag,
    l_linestatus,
    SUM(l_quantity) AS sum_quantity,
    SUM(l_extendedprice) AS sum_extended_price,
    SUM(l_discount) AS sum_discount,
    AVG(l_tax) AS avg_tax,
    COUNT(*) AS count_order
FROM 
    lineitem
WHERE 
    l_shipdate < '1998-12-01'
GROUP BY 
    l_returnflag, 
    l_linestatus
ORDER BY 
    l_returnflag, 
    l_linestatus;
