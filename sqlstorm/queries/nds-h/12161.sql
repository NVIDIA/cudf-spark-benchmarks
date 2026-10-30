SELECT 
    n_name AS nation, 
    r_name AS region, 
    COUNT(DISTINCT o_orderkey) AS order_count, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
FROM 
    customer 
JOIN 
    orders ON c_custkey = o_custkey 
JOIN 
    lineitem ON o_orderkey = l_orderkey 
JOIN 
    supplier ON s_suppkey = l_suppkey 
JOIN 
    partsupp ON ps_partkey = l_partkey AND ps_suppkey = s_suppkey 
JOIN 
    part ON p_partkey = l_partkey 
JOIN 
    nation ON n_nationkey = s_nationkey 
JOIN 
    region ON r_regionkey = n_regionkey 
WHERE 
    o_orderdate >= '1997-01-01' AND o_orderdate < '1998-01-01' 
GROUP BY 
    n_name, r_name 
ORDER BY 
    total_revenue DESC;