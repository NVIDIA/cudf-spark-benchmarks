SELECT 
    l_shipmode,
    COUNT(CASE WHEN l_returnflag = 'R' THEN 1 END) AS count_returned,
    SUM(l_extendedprice) AS total_extended_price,
    AVG(l_discount) AS avg_discount
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    l_shipmode;