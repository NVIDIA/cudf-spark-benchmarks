SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
    n_name, 
    extract(year from o_orderdate) AS year 
FROM 
    customer 
JOIN 
    orders ON c_custkey = o_custkey 
JOIN 
    lineitem ON o_orderkey = l_orderkey 
JOIN 
    partsupp ON l_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
JOIN 
    nation ON s_nationkey = n_nationkey 
GROUP BY 
    n_name, year 
ORDER BY 
    revenue DESC 
LIMIT 10;
