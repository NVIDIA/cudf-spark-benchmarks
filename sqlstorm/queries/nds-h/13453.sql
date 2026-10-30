SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ls.l_quantity) AS total_quantity,
    SUM(ls.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON ls.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;