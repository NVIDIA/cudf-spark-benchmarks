
SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    s_name,
    SUM(ps_supplycost * ps_availqty) AS total_cost,
    AVG(l_extendedprice) AS avg_price,
    COUNT(DISTINCT c_custkey) AS unique_customers,
    CONCAT('Region: ', r_name, ', Nation: ', n_name) AS location,
    LEFT(s_comment, 50) AS short_comment
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
JOIN 
    nation ON s_nationkey = n_nationkey 
JOIN 
    region ON n_regionkey = r_regionkey 
JOIN 
    lineitem ON p_partkey = l_partkey 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
WHERE 
    l_shipdate > '1997-01-01' 
GROUP BY 
    short_name, s_name, r_name, n_name, s_comment 
HAVING 
    COUNT(*) > 10 
ORDER BY 
    total_cost DESC, avg_price ASC
LIMIT 100;
