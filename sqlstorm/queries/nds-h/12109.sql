SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(YEAR FROM o_orderdate) AS o_year
FROM 
    customer
JOIN 
    orders ON c_custkey = o_custkey
JOIN 
    lineitem ON o_orderkey = l_orderkey
JOIN 
    supplier ON l_suppkey = s_suppkey
JOIN 
    partsupp ON l_partkey = ps_partkey AND s_suppkey = ps_suppkey
JOIN 
    part ON l_partkey = p_partkey
JOIN 
    nation ON s_nationkey = n_nationkey
GROUP BY 
    n_name, o_year
ORDER BY 
    revenue DESC, o_year ASC
LIMIT 10;
