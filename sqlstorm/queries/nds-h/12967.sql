SELECT 
    p.p_partkey,
    p.p_name,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
JOIN 
    orders o ON lo.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;