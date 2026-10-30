SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS sum_quantity, 
    SUM(l_extendedprice) AS sum_extended_price, 
    SUM(l_extendedprice * (1 - l_discount)) AS sum_disc_price, 
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge, 
    COUNT(*) AS count_order 
FROM 
    lineitem 
WHERE 
    l_shipdate <= DATE '1998-12-01' 
GROUP BY 
    l_returnflag, 
    l_linestatus 
ORDER BY 
    l_returnflag, 
    l_linestatus;
