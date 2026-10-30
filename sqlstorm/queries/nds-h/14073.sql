SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_sales
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey 
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1997-12-31' 
GROUP BY 
    p.p_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;