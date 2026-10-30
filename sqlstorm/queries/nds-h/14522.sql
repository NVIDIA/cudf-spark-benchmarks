SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS sum_quantity, 
    SUM(l_extendedprice) AS sum_extendedprice, 
    SUM(l_discount) AS sum_discount, 
    AVG(l_quantity) AS avg_quantity, 
    AVG(l_extendedprice) AS avg_extendedprice, 
    COUNT(*) AS count_order 
FROM 
    lineitem 
WHERE 
    l_shipdate >= '1995-01-01' 
    AND l_shipdate < '1996-01-01' 
GROUP BY 
    l_returnflag, 
    l_linestatus 
ORDER BY 
    l_returnflag, 
    l_linestatus;
