SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
WHERE 
    l_shipdate >= DATE '1998-01-01' 
    AND l_shipdate < DATE '1998-04-01' 
    AND n_name = 'GERMANY' 
GROUP BY 
    n_name 
ORDER BY 
    revenue DESC;
