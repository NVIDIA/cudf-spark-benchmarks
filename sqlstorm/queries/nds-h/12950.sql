SELECT 
    l_shipmode,
    AVG(l_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    order_count DESC;