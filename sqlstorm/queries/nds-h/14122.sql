SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS sum_quantity, 
    SUM(l_extendedprice) AS sum_extended_price, 
    SUM(l_discount) AS sum_discounted_price, 
    COUNT(*) AS count_order 
FROM 
    lineitem 
WHERE 
    l_shipdate >= '1994-01-01' AND l_shipdate <= '1995-12-31' 
GROUP BY 
    l_returnflag, 
    l_linestatus 
ORDER BY 
    l_returnflag, 
    l_linestatus;
