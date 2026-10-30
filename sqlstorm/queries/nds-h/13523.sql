SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' 
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    l.l_orderkey
ORDER BY 
    total_sales DESC
LIMIT 10;
