SELECT 
    l_suppkey,
    SUM(l_extendedprice) AS total_sales,
    COUNT(*) AS line_item_count
FROM 
    lineitem
WHERE 
    l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01'
GROUP BY 
    l_suppkey
ORDER BY 
    total_sales DESC
LIMIT 10;
