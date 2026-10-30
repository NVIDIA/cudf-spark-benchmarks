SELECT 
    l_shipmode,
    COUNT(DISTINCT o_orderkey) AS order_count,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    AVG(l_quantity) AS avg_quantity,
    COUNT(DISTINCT s_nationkey) AS unique_suppliers
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    partsupp ON l_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    nation ON s_nationkey = n_nationkey
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND o_orderstatus = 'F'
    AND l_returnflag = 'N'
GROUP BY 
    l_shipmode
ORDER BY 
    total_revenue DESC, 
    order_count DESC
LIMIT 10;