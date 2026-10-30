SELECT 
    substr(p_name, 1, 10) AS short_name, 
    count(*) AS part_count, 
    CONCAT(s_name, ', ', s_address) AS supplier_info, 
    r_name AS region_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
JOIN 
    lineitem ON ps_partkey = l_partkey 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
JOIN 
    region ON n_regionkey = r_regionkey 
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1998-01-01' 
GROUP BY 
    short_name, supplier_info, region_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;