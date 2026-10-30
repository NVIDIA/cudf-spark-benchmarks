SELECT 
    n.n_name AS nation, 
    r.r_name AS region, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
FROM 
    customer c 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
WHERE 
    o.o_orderdate >= '1996-01-01' 
    AND o.o_orderdate < '1997-01-01' 
GROUP BY 
    n.n_name, r.r_name 
ORDER BY 
    total_revenue DESC, total_orders DESC;