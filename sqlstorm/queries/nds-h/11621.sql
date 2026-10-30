SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    supplier 
JOIN 
    partsupp ON s_suppkey = ps_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    lineitem ON p_partkey = l_partkey 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
JOIN 
    nation ON s_nationkey = n_nationkey 
WHERE 
    o_orderdate >= '1997-01-01' 
    AND o_orderdate < '1997-12-31' 
GROUP BY 
    n_name 
ORDER BY 
    revenue DESC 
LIMIT 10;