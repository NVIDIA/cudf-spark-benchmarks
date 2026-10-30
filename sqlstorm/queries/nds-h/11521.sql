SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_sales
FROM 
    part
JOIN 
    lineitem ON p_partkey = l_partkey
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    nation ON s_nationkey = n_nationkey
GROUP BY 
    n_name
ORDER BY 
    total_sales DESC
LIMIT 10;
