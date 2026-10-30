SELECT 
    l_linenumber, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1996-01-01' + INTERVAL '1' YEAR
GROUP BY 
    l_linenumber
ORDER BY 
    revenue DESC
LIMIT 10;
