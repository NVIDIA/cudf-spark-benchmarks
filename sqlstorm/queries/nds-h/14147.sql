SELECT 
    n_name AS nation, 
    r_name AS region, 
    COUNT(DISTINCT o_orderkey) AS order_count, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    nation 
JOIN 
    region ON n_regionkey = r_regionkey 
JOIN 
    supplier ON n_nationkey = s_nationkey 
JOIN 
    partsupp ON s_suppkey = ps_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    lineitem ON p_partkey = l_partkey 
JOIN 
    orders ON l_orderkey = o_orderkey 
GROUP BY 
    n_name, r_name 
ORDER BY 
    revenue DESC;
