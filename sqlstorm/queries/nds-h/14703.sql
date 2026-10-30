SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    o.o_orderdate, 
    COUNT(DISTINCT l.l_partkey) AS unique_parts
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
GROUP BY 
    l.l_orderkey, o.o_orderdate
ORDER BY 
    revenue DESC
LIMIT 100;