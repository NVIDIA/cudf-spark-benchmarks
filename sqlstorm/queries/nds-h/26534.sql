SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s_name) AS unique_suppliers,
    CONCAT(r_name, ' - ', n_name) AS region_nation,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(CASE 
        WHEN l_discount > 0 THEN l_extendedprice * (1 - l_discount)
        ELSE l_extendedprice 
    END) AS avg_price_after_discount
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
JOIN 
    lineitem ON l_partkey = p_partkey 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
JOIN 
    region ON n_regionkey = r_regionkey 
WHERE 
    p_comment LIKE '%fragile%'
    AND o_orderstatus = 'O'
    AND l_shipdate >= '1997-01-01'
GROUP BY 
    short_name, region_nation 
ORDER BY 
    total_available_quantity DESC, unique_suppliers DESC;