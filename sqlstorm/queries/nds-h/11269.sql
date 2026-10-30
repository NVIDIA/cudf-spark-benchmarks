SELECT 
    l_partkey,
    SUM(l_quantity) AS total_quantity,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS average_discount,
    COUNT(DISTINCT l_orderkey) AS order_count
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
GROUP BY 
    l_partkey
ORDER BY 
    total_revenue DESC
LIMIT 100;
