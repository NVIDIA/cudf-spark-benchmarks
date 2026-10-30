SELECT 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    n.n_name AS nation, 
    o.o_orderdate
FROM 
    orders o 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey 
GROUP BY 
    o.o_orderkey, n.n_name, o.o_orderdate 
ORDER BY 
    revenue DESC 
LIMIT 10;
