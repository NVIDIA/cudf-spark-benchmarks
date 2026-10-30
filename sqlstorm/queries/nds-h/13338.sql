SELECT 
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate,
    COUNT(DISTINCT l.l_suppkey) AS supplier_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
GROUP BY 
    l.l_orderkey, o.o_orderdate
ORDER BY 
    revenue DESC
LIMIT 10;
