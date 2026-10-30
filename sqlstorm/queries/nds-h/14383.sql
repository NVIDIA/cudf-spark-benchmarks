SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS sum_quantity, 
    SUM(l_extendedprice) AS sum_extendedprice, 
    SUM(l_extendedprice * (1 - l_discount)) AS sum_discounted_price, 
    COUNT(*) AS cnt 
FROM 
    lineitem 
WHERE 
    l_shipdate >= DATE '1995-01-01' AND 
    l_shipdate < DATE '1996-01-01' 
GROUP BY 
    l_returnflag, 
    l_linestatus 
ORDER BY 
    l_returnflag, 
    l_linestatus;
