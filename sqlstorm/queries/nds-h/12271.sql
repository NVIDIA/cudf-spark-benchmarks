SELECT 
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS sales,
    o_orderdate,
    COUNT(DISTINCT l_partkey) AS unique_parts
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY 
    l_orderkey, o_orderdate
ORDER BY 
    sales DESC
LIMIT 100;