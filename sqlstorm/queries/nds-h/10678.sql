SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_quantity) AS sum_qty, 
    SUM(l_extendedprice) AS total_sum, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue, 
    AVG(l_quantity) AS avg_qty, 
    AVG(l_extendedprice) AS avg_price, 
    COUNT(*) AS count_order 
FROM 
    lineitem 
WHERE 
    l_shipdate >= DATE '1995-01-01' 
    AND l_shipdate < DATE '1996-01-01' 
GROUP BY 
    l_returnflag, 
    l_linestatus 
ORDER BY 
    l_returnflag, 
    l_linestatus;
