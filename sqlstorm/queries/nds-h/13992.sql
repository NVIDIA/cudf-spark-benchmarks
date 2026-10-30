SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS total_quantity, 
    SUM(l_extendedprice) AS total_extended_price, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_discounted_price, 
    COUNT(*) AS order_count
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1994-01-01' AND l_shipdate < DATE '1995-01-01'
GROUP BY 
    l_returnflag, 
    l_linestatus
ORDER BY 
    l_returnflag, 
    l_linestatus;
